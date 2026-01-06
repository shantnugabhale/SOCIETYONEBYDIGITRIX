# Om Shree Mahavir Society - Mobile App

A modern, clean, and intuitive Flutter mobile application for managing co-operative housing societies. Built with Material Design 3 principles and optimized for both Android and iOS platforms.

## 🏢 About

**Om Shree Mahavir Society** is a comprehensive society management solution designed to streamline operations for co-operative housing societies. The app provides a clean, minimalistic interface with professional design elements and smooth user experience.

## ✨ Features

### 🔐 Authentication Flow
- **Login Screen**: Clean email/phone + password authentication
- **Signup Screen**: Complete registration with flat number validation
- **Mobile OTP Verification**: Secure 6-digit OTP verification
- **Forgot Password**: Password reset functionality

### 👤 User Features
- **Dashboard**: Overview cards with due amounts, next due date, and quick actions
- **Profile Management**: Edit personal information, flat details, and contact info
- **Payment Management**: View current bills, payment history, and receipts
- **Utility Bills**: Track electricity, water, elevator, gas, and parking bills
- **Maintenance Requests**: Submit and track maintenance requests
- **Complaints**: Submit complaints and view resolution status
- **Notices**: View society notices and announcements

### 👨‍💼 Admin Features
- **Admin Dashboard**: Comprehensive overview with key metrics
- **Member Management**: Add, edit, and manage society members
- **Payment Management**: Track payments, generate receipts
- **Utility Bills Management**: Manage all utility bills
- **Ledger & Accounts**: Financial reports and profit/loss tracking
- **Maintenance Requests**: Assign and track maintenance tasks
- **Complaints Management**: Handle and resolve complaints
- **Notices Management**: Create and manage society notices

## 🎨 Design System

### Color Palette
- **Primary Blue**: `#4A90E2` - Main brand color
- **Soft Blue**: `#EAF4FF` - Light background accents
- **Soft Gray**: `#F5F7FA` - Surface colors
- **Success**: `#16A34A` - Paid status
- **Warning**: `#F59E0B` - Pending status
- **Danger**: `#EF4444` - Overdue status

### Typography
- **Font Family**: Poppins (clean, modern sans-serif)
- **H1/Screen Title**: 20-22sp
- **H2/Section Title**: 16-18sp
- **Body Text**: 14sp
- **Small/Captions**: 12sp

### Components
- **Rounded Corners**: 8px base radius for cards and buttons
- **Shadows**: Subtle elevation with soft shadows
- **Touch Targets**: Minimum 48x48px for accessibility
- **Spacing**: 8px base unit for consistent spacing

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App setup (theme, initial route, GetX bindings)
│
├── constants/
│   ├── colors.dart           # App color palette
│   ├── strings.dart          # Text strings
│   └── styles.dart           # Text styles, paddings, etc.
│
├── models/
│   ├── user_model.dart
│   ├── member_model.dart
│   ├── payment_model.dart
│   ├── ledger_model.dart
│   ├── notice_model.dart
│   └── utility_model.dart
│
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── payment_service.dart
│   ├── utility_service.dart
│   ├── maintenance_service.dart
│   └── notice_service.dart
│
├── controllers/               # GetX Controllers
│   ├── auth_controller.dart
│   ├── user_controller.dart
│   ├── admin_controller.dart
│   ├── payment_controller.dart
│   ├── ledger_controller.dart
│   ├── utility_controller.dart
│   ├── maintenance_controller.dart
│   └── notice_controller.dart
│
├── routes/
│   └── app_routes.dart        # GetX routing
│
├── utils/
│   ├── date_utils.dart
│   └── validators.dart
│
├── widgets/                   # Reusable UI components
│   ├── custom_button.dart
│   ├── card_widget.dart
│   ├── chart_widget.dart
│   └── input_field.dart
│
├── views/
│   ├── splash/
│   │   └── splash_screen.dart
│   │
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── mobile_otp_verification.dart
│   │   ├── email_verification.dart
│   │   ├── forgot_password_screen.dart
│   │   └── reset_password_screen.dart
│   │
│   ├── user/
│   │   ├── dashboard_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── utility_bills_screen.dart
│   │   ├── payment_history_screen.dart
│   │   ├── revenue_screen.dart
│   │   ├── maintenance_status_screen.dart
│   │   ├── complaints_screen.dart
│   │   └── notices_screen.dart
│   │
│   ├── admin/
│   │   ├── admin_dashboard.dart
│   │   ├── profile_screen.dart
│   │   ├── member_management.dart
│   │   ├── payment_management.dart
│   │   ├── utility_bills_management.dart
│   │   │    ├── electricity_bill.dart
│   │   │    ├── water_bill.dart
│   │   │    ├── elevator_bill.dart
│   │   │    └── other_services.dart
│   │   ├── ledger_screen.dart
│   │   ├── revenue_screen.dart
│   │   ├── maintenance_requests.dart
│   │   ├── complaints_management.dart
│   │   └── notices_management.dart
│   │
│   └── common/
│       └── error_screen.dart
│
└── theme/
    ├── light_theme.dart
    └── dark_theme.dart
```

## Dependencies

- **get**: State management and routing
- **fl_chart**: Charts and graphs
- **intl**: Internationalization and date formatting
- **http**: HTTP requests
- **shared_preferences**: Local storage
- **image_picker**: Image selection
- **path_provider**: File system access
- **pdf**: PDF generation
- **qr_flutter**: QR code generation
- **table_calendar**: Calendar widget
- **flutter_spinkit**: Loading indicators
- **fluttertoast**: Toast messages
- **permission_handler**: Permission management
- **connectivity_plus**: Network connectivity
- **device_info_plus**: Device information
- **package_info_plus**: Package information

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd society_management_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Features Implemented

### ✅ Completed
- [x] Project structure and folder organization
- [x] Color palette and theme configuration
- [x] Text styles and constants
- [x] Data models for all entities
- [x] Reusable UI components
- [x] Custom input fields and buttons
- [x] Chart widgets for analytics
- [x] Card widgets for data display
- [x] Splash screen with animations
- [x] Login screen with validation
- [x] User dashboard with overview
- [x] Admin dashboard with metrics
- [x] Payment screen with multiple options
- [x] Routing configuration
- [x] Utility functions for dates and validation
- [x] Responsive design principles

### 🚧 In Progress
- [ ] Service layer implementation
- [ ] Controller implementation
- [ ] Authentication flow
- [ ] Database integration
- [ ] API integration
- [ ] File upload functionality
- [ ] Push notifications
- [ ] Offline support

### 📋 Planned
- [ ] Signup screen
- [ ] Forgot password screen
- [ ] Profile management
- [ ] Payment history
- [ ] Utility bills management
- [ ] Maintenance requests
- [ ] Complaints system
- [ ] Notices management
- [ ] Revenue analytics
- [ ] Member management
- [ ] Settings and preferences
- [ ] Dark mode support
- [ ] Multi-language support

## Design Principles

### UI/UX
- **Material Design 3**: Following Google's latest design guidelines
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: Screen reader support and high contrast
- **Consistent Theming**: Light and dark theme support
- **Intuitive Navigation**: Clear navigation patterns

### Architecture
- **Clean Architecture**: Separation of concerns
- **MVVM Pattern**: Model-View-ViewModel with GetX
- **Dependency Injection**: Loose coupling between components
- **Repository Pattern**: Data access abstraction
- **Service Layer**: Business logic separation

### Code Quality
- **Type Safety**: Strong typing throughout
- **Error Handling**: Comprehensive error management
- **Validation**: Input validation and sanitization
- **Documentation**: Well-documented code
- **Testing**: Unit and widget tests

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- GetX team for state management
- Material Design team for design guidelines
- Open source community for various packages#   s o c i e t y - m a n a g e m e n t - a p p  
 