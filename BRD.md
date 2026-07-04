# Business Requirement

## Vision

Build an integrated church management platform that digitizes member administration, church activities, service registration, documentation, and communication.

## Business Goals

- Centralized member management
- Online service registration
- Event scheduling
- Automatic reminders
- Church news
- Documentation archive
- Better communication

## User Roles (RBAC)

### Church Staff / Admin - Super Admin

- Login
- Manage Members
- Manage Activities
- Manage News
- Manage Gallery
- Manage Service Requests
- Approve Requests
- Schedule Notifications

### Church Member

- Register
- Login
- Browse Activities
- Browse News
- Submit Requests
- Receive Notifications
- View Gallery
- Download Media
- Edit Profile

## Core Business Rules

- Every service request requires review.
- Notifications support H-2 and H-1 scheduling.
- Documentation can contain images and videos.
- News is publicly readable.
- Members cannot access administration features.