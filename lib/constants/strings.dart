class AppStrings {
  // App Info
  static const String appName = 'SocietyOne by Digitrix';
  static const String appShortName = 'SocietyOne';
  static const String appVersion = '1.0.0';
  
  // Authentication
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String mobileNumber = 'Mobile Number';
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  
  // Navigation
  static const String dashboard = 'Dashboard';
  static const String profile = 'Profile';
  static const String payments = 'Payments';
  static const String utilities = 'Utilities';
  static const String maintenance = 'Maintenance';
  static const String notices = 'Notices';
  static const String complaints = 'Complaints';
  static const String revenue = 'Revenue';
  static const String ledger = 'Ledger';
  static const String members = 'Members';
  
  // User Dashboard
  static const String welcomeBack = 'Welcome Back';
  static const String totalPayments = 'Total Payments';
  static const String pendingPayments = 'Pending Payments';
  static const String recentPayments = 'Recent Payments';
  static const String upcomingBills = 'Upcoming Bills';
  static const String maintenanceRequests = 'Maintenance Requests';
  static const String newNotices = 'New Notices';
  
  // Admin Dashboard
  static const String adminDashboard = 'Admin Dashboard';
  static const String totalMembers = 'Total Members';
  static const String totalRevenue = 'Total Revenue';
  static const String pendingRequests = 'Pending Requests';
  static const String overduePayments = 'Overdue Payments';
  static const String memberManagement = 'Member Management';
  static const String paymentManagement = 'Payment Management';
  static const String utilityBillsManagement = 'Utility Bills Management';
  static const String maintenanceRequestsManagement = 'Maintenance Requests';
  static const String complaintsManagement = 'Complaints Management';
  static const String noticesManagement = 'Notices Management';
  
  // Payment
  static const String makePayment = 'Make Payment';
  static const String paymentHistory = 'Payment History';
  static const String paymentStatus = 'Payment Status';
  static const String amount = 'Amount';
  static const String dueDate = 'Due Date';
  static const String paidDate = 'Paid Date';
  static const String paymentMethod = 'Payment Method';
  static const String transactionId = 'Transaction ID';
  static const String paid = 'Paid';
  static const String pending = 'Pending';
  static const String overdue = 'Overdue';
  
  // Utility Bills
  static const String electricityBill = 'Electricity Bill';
  static const String waterBill = 'Water Bill';
  static const String gasBill = 'Gas Bill';
  static const String elevatorBill = 'Elevator Bill';
  static const String otherServices = 'Other Services';
  static const String billAmount = 'Bill Amount';
  static const String units = 'Units';
  static const String rate = 'Rate';
  
  // Maintenance
  static const String maintenanceRequest = 'Maintenance Request';
  static const String requestType = 'Request Type';
  static const String description = 'Description';
  static const String priority = 'Priority';
  static const String status = 'Status';
  static const String assignedTo = 'Assigned To';
  static const String requestedDate = 'Requested Date';
  static const String completedDate = 'Completed Date';
  static const String high = 'High';
  static const String medium = 'Medium';
  static const String low = 'Low';
  static const String open = 'Open';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String closed = 'Closed';
  
  // Notices
  static const String noticeTitle = 'Notice Title';
  static const String noticeContent = 'Notice Content';
  static const String publishDate = 'Publish Date';
  static const String expiryDate = 'Expiry Date';
  static const String createNotice = 'Create Notice';
  static const String editNotice = 'Edit Notice';
  static const String deleteNotice = 'Delete Notice';
  
  // Complaints
  static const String complaintTitle = 'Complaint Title';
  static const String complaintDescription = 'Complaint Description';
  static const String submitComplaint = 'Submit Complaint';
  static const String complaintStatus = 'Complaint Status';
  static const String resolution = 'Resolution';
  static const String resolvedDate = 'Resolved Date';
  
  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String update = 'Update';
  static const String submit = 'Submit';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String sort = 'Sort';
  static const String refresh = 'Refresh';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';
  static const String confirm = 'Confirm';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String ok = 'OK';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String done = 'Done';
  static const String continueText = 'Continue';
  
  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String mobileRequired = 'Mobile number is required';
  static const String mobileInvalid = 'Please enter a valid mobile number';
  static const String otpRequired = 'OTP is required';
  static const String otpInvalid = 'Please enter a valid OTP';
  static const String nameRequired = 'Name is required';
  static const String amountRequired = 'Amount is required';
  static const String amountInvalid = 'Please enter a valid amount';
  static const String dateRequired = 'Date is required';
  static const String descriptionRequired = 'Description is required';
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';
  static const String loginFailed = 'Login failed. Please check your credentials.';
  static const String signupFailed = 'Sign up failed. Please try again.';
  static const String otpVerificationFailed = 'OTP verification failed.';
  static const String passwordResetFailed = 'Password reset failed.';
  static const String paymentFailed = 'Payment failed. Please try again.';
  static const String dataLoadFailed = 'Failed to load data.';
  static const String dataSaveFailed = 'Failed to save data.';
  static const String dataDeleteFailed = 'Failed to delete data.';
}
