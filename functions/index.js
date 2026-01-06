const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// ============================================
// CASE M1 - New Notice Created
// ============================================
exports.sendNoticeNotification = onDocumentCreated(
  {
    document: "notices/{noticeId}",
    region: "us-central1",
  },
  async (event) => {
    const noticeData = event.data.data();
    if (!noticeData) {
      logger.error("No notice data found");
      return;
    }

    const title = noticeData.title || "New Notice";
    const content = noticeData.content || "";
    const attachments = noticeData.attachments || [];
    const noticeId = event.params.noticeId;
    const category = noticeData.category || "general";
    const priority = noticeData.priority || "medium";
    
    // Analyze attachments
    let imageUrl = null;
    let pdfUrls = [];
    let imageCount = 0;
    let pdfCount = 0;
    
    if (attachments && attachments.length > 0) {
      for (const url of attachments) {
        const extension = url.split('.').pop()?.toLowerCase().split('?')[0];
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(extension)) {
          if (!imageUrl) imageUrl = url; // Use first image for notification
          imageCount++;
        } else if (extension === 'pdf') {
          pdfUrls.push(url);
          pdfCount++;
        }
      }
    }

    // Build professional notification body (without attachment text)
    let body = content.length > 120 ? content.substring(0, 120) + "..." : content;
    if (body.trim() === "") {
      body = "Tap to view notice details";
    }

    // Build priority-based title
    let notificationTitle = "New Notice Published";
    if (priority === "urgent") {
      notificationTitle = "🚨 Urgent Notice";
    } else if (priority === "high") {
      notificationTitle = "⚠️ Important Notice";
    }

    // Build Android-specific notification with professional structure
    const androidConfig = {
      notification: {
        title: notificationTitle,
        body: body,
        priority: priority === "urgent" ? "max" : "high",
        sound: "default",
        channelId: "high_importance_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        ...(imageUrl && { imageUrl: imageUrl }),
        tag: noticeId, // Group notifications by notice ID
      },
    };

    // Build professional message structure
    const message = {
      notification: {
        title: notificationTitle,
        body: body,
        ...(imageUrl && { imageUrl: imageUrl }),
      },
      android: androidConfig,
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationTitle,
              body: body,
            },
            sound: "default",
            badge: 1,
            category: "NOTICE_CATEGORY",
            "thread-id": "notices",
          },
          ...(imageUrl && { fcm_options: { image: imageUrl } }),
        },
      },
      data: {
        type: "notice",
        noticeId: noticeId,
        title: title,
        category: category,
        priority: priority,
        hasAttachments: attachments.length > 0 ? "true" : "false",
        attachmentCount: attachments.length.toString(),
        imageCount: imageCount.toString(),
        pdfCount: pdfCount.toString(),
        imageUrl: imageUrl || "",
        pdfUrls: JSON.stringify(pdfUrls),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      topic: "all_users",
    };

    try {
      await admin.messaging().send(message);
      logger.info("Successfully sent notice notification with attachments");
    } catch (error) {
      logger.error("Error sending notice notification:", error);
    }
  }
);

// ============================================
// CASE M2 - Maintenance Status Updated
// ============================================
exports.sendMaintenanceStatusUpdateNotification = onDocumentUpdated(
  {
    document: "maintenance_requests/{requestId}",
    region: "us-central1",
  },
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    if (!beforeData || !afterData) return;

    const oldStatus = beforeData.status;
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return;

    const title = afterData.title || "Maintenance Request";
    const userId = afterData.userId;

    let userToken = null;
    if (userId) {
      try {
        const userDoc = await admin.firestore().collection("members").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          userToken = userData?.fcmToken;
        }
      } catch (error) {
        logger.error("Error fetching user token:", error);
      }
    }

    if (!userToken) {
      logger.warn(`No FCM token found for user ${userId}`);
      return;
    }

    let notificationTitle = "";
    let notificationBody = "";

    if (newStatus === "in_progress") {
      notificationTitle = "Maintenance Started";
      notificationBody = `Your maintenance request '${title}' is now in progress.`;
    } else if (newStatus === "completed") {
      notificationTitle = "Maintenance Completed";
      notificationBody = `Your maintenance request '${title}' has been completed.`;
    } else if (newStatus === "rejected") {
      notificationTitle = "Request Rejected";
      notificationBody = `Your request '${title}' was rejected.`;
    } else {
      return;
    }

    const message = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      token: userToken,
    };

    try {
      await admin.messaging().send(message);
      logger.info(`Sent status update notification for status: ${newStatus}`);
    } catch (error) {
      logger.error("Error sending status update notification:", error);
    }
  }
);

// ============================================
// CASE M3 - New Utility Bill Created
// ============================================
exports.sendUtilityBillNotification = onDocumentCreated(
  {
    document: "utility_bills/{billId}",
    region: "us-central1",
  },
  async (event) => {
    const billData = event.data.data();
    if (!billData) {
      logger.error("No utility bill data found");
      return;
    }

    const type = billData.utilityType || "Utility";
    const amount = billData.totalAmount || 0;
    let dueDate = "N/A";
    if (billData.dueDate) {
      try {
        const date = billData.dueDate.toDate ? billData.dueDate.toDate() : new Date(billData.dueDate);
        dueDate = date.toLocaleDateString();
      } catch (e) {
        dueDate = "N/A";
      }
    }

    const message = {
      notification: {
        title: "New Bill Generated",
        body: `${type} bill ₹${amount} • Due: ${dueDate}`,
      },
      topic: "all_users",
    };

    try {
      await admin.messaging().send(message);
      logger.info("Successfully sent utility bill notification");
    } catch (error) {
      logger.error("Error sending utility bill notification:", error);
    }
  }
);

// ============================================
// CASE M4 - Billing Reminder (Scheduled Daily)
// ============================================
exports.sendBillingReminder = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Asia/Kolkata",
    region: "us-central1",
  },
  async (event) => {
    try {
      const now = new Date();
      const twoDaysLater = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000);

      const bills = await admin.firestore()
        .collection("utility_bills")
        .where("isActive", "==", true)
        .where("status", "in", ["pending", "overdue"])
        .get();

      let hasUpcomingBills = false;
      bills.forEach((doc) => {
        const billData = doc.data();
        const dueDateStr = billData.dueDate;
        if (dueDateStr) {
          try {
            const dueDate = dueDateStr.toDate ? dueDateStr.toDate() : new Date(dueDateStr);
            if (dueDate <= twoDaysLater && dueDate > now) {
              hasUpcomingBills = true;
            }
          } catch (e) {
            logger.warn("Error parsing due date:", e);
          }
        }
      });

      if (hasUpcomingBills) {
        const message = {
          notification: {
            title: "Payment Reminder",
            body: "Only 2 days left to pay your bill.",
          },
          topic: "all_users",
        };

        await admin.messaging().send(message);
        logger.info("Sent billing reminder to all users");
      }
    } catch (error) {
      logger.error("Error in billing reminder function:", error);
    }
  }
);

// ============================================
// CASE M5 - Payment Confirmation
// ============================================
exports.sendPaymentConfirmation = onDocumentCreated(
  {
    document: "payments/{paymentId}",
    region: "us-central1",
  },
  async (event) => {
    const paymentData = event.data.data();
    if (!paymentData) {
      logger.error("No payment data found");
      return;
    }

    const userId = paymentData.userId;
    const amount = paymentData.amount || 0;
    const txnId = paymentData.transactionId || paymentData.id || "N/A";

    if (!userId) return;

    let userToken = null;
    try {
      const userDoc = await admin.firestore().collection("members").doc(userId).get();
      if (userDoc.exists) {
        const userData = userDoc.data();
        userToken = userData?.fcmToken;
      }
    } catch (error) {
      logger.error("Error fetching user token:", error);
    }

    if (!userToken) {
      logger.warn(`No FCM token found for user ${userId}`);
      return;
    }

    const message = {
      notification: {
        title: "Payment Successful",
        body: `₹${amount} received. Transaction ID: ${txnId}`,
      },
      token: userToken,
    };

    try {
      await admin.messaging().send(message);
      logger.info(`Sent payment confirmation to user ${userId}`);
    } catch (error) {
      logger.error("Error sending payment confirmation:", error);
    }
  }
);

// ============================================
// CASE M6 - Overdue Alert (Scheduled Daily)
// ============================================
exports.sendOverdueAlert = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: "Asia/Kolkata",
    region: "us-central1",
  },
  async (event) => {
    try {
      const now = new Date();

      const bills = await admin.firestore()
        .collection("utility_bills")
        .where("isActive", "==", true)
        .where("status", "in", ["pending", "overdue"])
        .get();

      let hasOverdueBills = false;
      bills.forEach((doc) => {
        const billData = doc.data();
        const dueDateStr = billData.dueDate;
        if (dueDateStr) {
          try {
            const dueDate = dueDateStr.toDate ? dueDateStr.toDate() : new Date(dueDateStr);
            if (dueDate < now) {
              hasOverdueBills = true;
            }
          } catch (e) {
            logger.warn("Error parsing due date:", e);
          }
        }
      });

      if (hasOverdueBills) {
        const message = {
          notification: {
            title: "Overdue Bill",
            body: "Your bill is overdue. Please make payment.",
          },
          topic: "all_users",
        };

        await admin.messaging().send(message);
        logger.info("Sent overdue alert to all users");
      }
    } catch (error) {
      logger.error("Error in overdue alert function:", error);
    }
  }
);

// ============================================
// CASE A1 - New Maintenance Request Submitted
// ============================================
exports.sendMaintenanceRequestNotification = onDocumentCreated(
  {
    document: "maintenance_requests/{requestId}",
    region: "us-central1",
  },
  async (event) => {
    const requestData = event.data.data();
    if (!requestData) {
      logger.error("No maintenance request data found");
      return;
    }

    const title = requestData.title || "New Maintenance Request";
    const flatNo = requestData.userApartment || "N/A";
    const priority = requestData.priority || "medium";
    const type = requestData.type || "other";
    const requestId = event.params.requestId;
    const isPublic = requestData.isPublic === true;

    // Helper function to get priority emoji and label
    const getPriorityInfo = (priority) => {
      const p = priority.toLowerCase();
      if (p === "high") return { emoji: "🔴", label: "High Priority" };
      if (p === "low") return { emoji: "🟢", label: "Low Priority" };
      return { emoji: "🟡", label: "Normal Priority" };
    };

    const priorityInfo = getPriorityInfo(priority);
    const notificationTitle = `${priorityInfo.emoji} New Maintenance Request`;
    const notificationBody = `${priorityInfo.emoji} Priority: ${priorityInfo.label}\n\nFlat ${flatNo}: ${title}`;

    const androidConfig = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
        priority: priority === "high" ? "max" : priority === "low" ? "normal" : "high",
        sound: "default",
        channelId: "high_importance_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    const messageData = {
      type: "maintenance",
      requestId: requestId,
      title: title,
      status: requestData.status || "open",
      priority: priority,
      typeCategory: type,
      userApartment: flatNo,
      isPublic: isPublic ? "true" : "false",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    };

    // Always notify admins
    const adminMessage = {
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      android: androidConfig,
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationTitle,
              body: notificationBody,
            },
            sound: "default",
            badge: 1,
            category: "MAINTENANCE_CATEGORY",
            "thread-id": "maintenance",
          },
        },
      },
      data: messageData,
      topic: "maintenance_admins",
    };

    try {
      await admin.messaging().send(adminMessage);
      logger.info("Sent maintenance request notification to admins with priority");
    } catch (error) {
      logger.error("Error sending maintenance request notification to admins:", error);
    }

    // If public, also notify all users
    if (isPublic) {
      const publicMessage = {
        notification: {
          title: `${priorityInfo.emoji} New Public Maintenance Request`,
          body: `Flat ${flatNo}: ${title} (${priorityInfo.label})`,
        },
        android: {
          notification: {
            title: `${priorityInfo.emoji} New Public Maintenance Request`,
            body: `Flat ${flatNo}: ${title} (${priorityInfo.label})`,
            priority: priority === "high" ? "max" : priority === "low" ? "normal" : "high",
            sound: "default",
            channelId: "high_importance_channel",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: `${priorityInfo.emoji} New Public Maintenance Request`,
                body: `Flat ${flatNo}: ${title} (${priorityInfo.label})`,
              },
              sound: "default",
              badge: 1,
              category: "MAINTENANCE_CATEGORY",
              "thread-id": "maintenance",
            },
          },
        },
        data: messageData,
        topic: "all_users",
      };

      try {
        await admin.messaging().send(publicMessage);
        logger.info("Sent public maintenance request notification to all users");
      } catch (error) {
        logger.error("Error sending public maintenance request notification:", error);
      }
    }
  }
);

// ============================================
// CASE A2 - Payment Received
// ============================================
exports.sendPaymentReceivedNotification = onDocumentCreated(
  {
    document: "payments/{paymentId}",
    region: "us-central1",
  },
  async (event) => {
    const paymentData = event.data.data();
    if (!paymentData) {
      logger.error("No payment data found");
      return;
    }

    const userId = paymentData.userId;
    const amount = paymentData.amount || 0;

    let flatNo = "N/A";
    if (userId) {
      try {
        const userDoc = await admin.firestore().collection("members").doc(userId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          flatNo = userData?.apartmentNumber || userData?.userApartment || "N/A";
        }
      } catch (error) {
        logger.error("Error fetching user data:", error);
      }
    }

    const message = {
      notification: {
        title: "Payment Received",
        body: `Flat ${flatNo} paid ₹${amount}.`,
      },
      topic: "maintenance_admins",
    };

    try {
      await admin.messaging().send(message);
      logger.info("Sent payment received notification to admins");
    } catch (error) {
      logger.error("Error sending payment received notification:", error);
    }
  }
);

// ============================================
// CASE A3 - New Member Registered
// ============================================
exports.sendNewMemberNotification = onDocumentCreated(
  {
    document: "members/{memberId}",
    region: "us-central1",
  },
  async (event) => {
    const memberData = event.data.data();
    if (!memberData) {
      logger.error("No member data found");
      return;
    }

    const name = memberData.name || "New Member";
    const flatNo = memberData.apartmentNumber || "N/A";

    const message = {
      notification: {
        title: "New Member Joined",
        body: `${name} from Flat ${flatNo} registered.`,
      },
      topic: "maintenance_admins",
    };

    try {
      await admin.messaging().send(message);
      logger.info("Sent new member notification to admins");
    } catch (error) {
      logger.error("Error sending new member notification:", error);
    }
  }
);
