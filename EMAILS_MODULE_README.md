# Emails Module & EstimateRequest Module

This document describes the implementation of the **Emails Module** and **EstimateRequest Module** for the Flutter CMS application.

## Overview

Both modules have been implemented following the existing application architecture and design patterns, ensuring consistency with the overall user experience.

## Emails Module

### Features
- **Email Account Management**: View, add, and manage email accounts
- **Email Messages**: Browse, search, and filter email messages
- **Folder Navigation**: Support for standard email folders (Inbox, Sent, Drafts, etc.)
- **Search & Filtering**: Advanced search and filtering capabilities
- **Statistics**: Account and message statistics dashboard

### Architecture
```
lib/features/email/
├── presentation/
│   ├── pages/
│   │   ├── email_main_page.dart          # Main email management page
│   │   ├── email_accounts_page.dart      # Email accounts listing
│   │   └── email_messages_page.dart      # Email messages for an account
│   └── widgets/
│       ├── email_account_card.dart       # Email account display card
│       ├── email_message_card.dart       # Email message display card
│       └── email_folders_sidebar.dart    # Folder navigation sidebar
```

### Key Components

#### EmailMainPage
- Entry point for the email module
- Displays email accounts with statistics
- Search and filtering capabilities
- Tab-based navigation (All, Active, Inactive)

#### EmailMessagesPage
- Displays messages for a specific email account
- Folder-based navigation
- Message filtering (All, Unread, Starred, Important)
- Search functionality

#### EmailAccountCard
- Displays email account information
- Shows connection status, sync information, and statistics
- Visual indicators for account health

#### EmailMessageCard
- Displays individual email messages
- Shows sender, subject, snippet, and metadata
- Visual indicators for read status, attachments, and priority

### API Integration
The module integrates with the Laravel API endpoints:
- `GET /email-accounts` - List email accounts
- `GET /email-messages` - List email messages
- `POST /email-accounts` - Create email account
- `PUT /email-accounts/{id}` - Update email account
- `DELETE /email-accounts/{id}` - Delete email account

## EstimateRequest Module

### Features
- **Request Management**: Create, view, edit, and delete estimate requests
- **Status Tracking**: Track request status through workflow
- **Assignment**: Assign requests to staff members
- **Estimate Linking**: Link requests to actual estimates
- **Advanced Filtering**: Filter by status, priority, source, and more
- **Statistics Dashboard**: Comprehensive request analytics

### Architecture
```
lib/features/estimates/
├── presentation/
│   ├── pages/
│   │   └── estimate_requests_page.dart   # Main estimate requests page
│   └── widgets/
│       ├── estimate_request_card.dart     # Request display card
│       └── estimate_request_statistics_card.dart # Statistics display
```

### Key Components

#### EstimateRequestsPage
- Main page for managing estimate requests
- Tab-based filtering (All, New, In Progress, Completed, Archived)
- Advanced search and filtering options
- Statistics dashboard integration

#### EstimateRequestCard
- Displays estimate request information
- Shows contact details, requirements, and status
- Quick action buttons for common operations
- Visual indicators for urgency and follow-up

#### EstimateRequestStatisticsCard
- Displays key metrics and statistics
- Visual representation of request data
- Real-time updates from the API

### API Integration
The module integrates with the Laravel API endpoints:
- `GET /estimate-requests` - List estimate requests
- `POST /estimate-requests` - Create estimate request
- `GET /estimate-requests/{id}` - Get request details
- `PUT /estimate-requests/{id}` - Update request
- `DELETE /estimate-requests/{id}` - Delete request
- `POST /estimate-requests/{id}/assign-estimate` - Link to estimate
- `POST /estimate-requests/{id}/assign-staff` - Assign to staff
- `POST /estimate-requests/{id}/change-status` - Change status

## Data Models

### Email Models
- `EmailAccount`: Email account configuration and status
- `EmailMessage`: Individual email message with metadata
- `EmailAttachment`: File attachments
- `EmailFolder`: Email folder structure

### EstimateRequest Models
- `EstimateRequest`: Main request entity
- `EstimateRequestStatus`: Status definitions
- `EstimateRequestFormData`: Form configuration data

## State Management

Both modules use **Provider** pattern for state management:

- `EmailProvider`: Manages email accounts and messages
- `EstimateRequestsProvider`: Manages estimate requests

## Navigation

### Email Module Routes
- `/email` - Main email management page
- `/email/messages/{accountId}` - Messages for specific account

### EstimateRequest Module Routes
- `/estimate-requests` - Main estimate requests page

## UI/UX Features

### Design Consistency
- Follows the existing app's gradient design theme
- Consistent color scheme (primary: #1B4D3E)
- Modern card-based layouts
- Responsive design patterns

### Interactive Elements
- Pull-to-refresh functionality
- Infinite scrolling for large lists
- Search and filtering
- Tab-based navigation
- Floating action buttons

### Visual Indicators
- Status badges with colors
- Connection status indicators
- Priority and urgency markers
- Attachment indicators

## Future Enhancements

### Email Module
- [ ] Email composition interface
- [ ] Attachment handling
- [ ] Email signatures
- [ ] Auto-sync configuration
- [ ] Push notifications

### EstimateRequest Module
- [ ] Request creation wizard
- [ ] Advanced workflow management
- [ ] Integration with CRM contacts
- [ ] Automated follow-up scheduling
- [ ] Reporting and analytics

## Technical Notes

### Dependencies
- Flutter 3.5.4+
- Provider for state management
- GoRouter for navigation
- Easy Localization for internationalization

### Performance Considerations
- Pagination for large datasets
- Lazy loading of message content
- Efficient image caching
- Optimized list rendering

### Security
- API authentication via tokens
- Input validation and sanitization
- Secure storage of credentials
- HTTPS communication

## Testing

Both modules include comprehensive error handling and loading states:
- Loading indicators
- Error messages with retry options
- Empty state handling
- Network error recovery

## Conclusion

The Emails Module and EstimateRequest Module provide a solid foundation for email management and estimate request handling within the CMS application. They follow established patterns and integrate seamlessly with the existing codebase while providing modern, user-friendly interfaces for managing these critical business processes.