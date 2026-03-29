# API Integration Flow Diagram

## Complete Authentication & Profile Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER OPENS APP                              │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  Login Screen  │
                    └────────┬───────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌──────────────┐          ┌──────────────┐
        │  Phone OTP   │          │ Google Sign  │
        │   Firebase   │          │   Firebase   │
        └──────┬───────┘          └──────┬───────┘
               │                         │
               └────────────┬────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │  Get Firebase Token   │
                └───────────┬───────────┘
                            │
                            ▼
                ┌───────────────────────────────────┐
                │  POST /api/auth/login             │
                │  Headers: Bearer <firebase_token> │
                │  Body: {                          │
                │    auth_provider: "phone/google"  │
                │    mobile: "+919876543210"        │
                │    email: "user@example.com"      │
                │    name: "User Name"              │
                │  }                                │
                └───────────┬───────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │  Backend Response:    │
                │  {                    │
                │    success: true,     │
                │    is_new_user: bool, │
                │    user: {...}        │
                │  }                    │
                └───────────┬───────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
        is_new_user = true       is_new_user = false
        OR profile incomplete    AND profile complete
                │                       │
                ▼                       ▼
    ┌──────────────────────┐    ┌──────────────┐
    │ Profile Setup Screen │    │  Home Screen │
    └──────────┬───────────┘    └──────────────┘
               │
               ▼
    ┌──────────────────────────────────┐
    │  User Fills Profile Form:        │
    │  - Name                           │
    │  - Gender                         │
    │  - Date of Birth                  │
    │  - Address                        │
    │  - State                          │
    │  - Pincode                        │
    └──────────┬───────────────────────┘
               │
               ▼
    ┌──────────────────────────────────┐
    │  POST /api/user/profile          │
    │  Headers: Bearer <firebase_token>│
    │  Body: {                         │
    │    name: "Full Name",            │
    │    gender: "Male",               │
    │    date_of_birth: "01/01/1990",  │
    │    address: "123 Main St",       │
    │    state: "Telangana",           │
    │    pincode: "500001"             │
    │  }                               │
    └──────────┬───────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Backend Response:   │
    │  {                   │
    │    success: true,    │
    │    user: {...}       │
    │  }                   │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Permission Screen   │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────────────────┐
    │  Request Permissions:            │
    │  - Camera                        │
    │  - Microphone                    │
    │  - Notifications                 │
    └──────────┬───────────────────────┘
               │
               ▼
    ┌──────────────────────────────────┐
    │  POST /api/user/permissions      │
    │  Headers: Bearer <firebase_token>│
    │  Body: {                         │
    │    camera: true,                 │
    │    microphone: true,             │
    │    notifications: true           │
    │  }                               │
    └──────────┬───────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │  Backend Response:   │
    │  {                   │
    │    success: true     │
    │  }                   │
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │    Home Screen       │
    └──────────────────────┘
```

## Additional API Operations

### Fetch User Profile
```
┌──────────────────────────────────┐
│  GET /api/user/profile           │
│  Headers: Bearer <firebase_token>│
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────┐
│  Response:           │
│  {                   │
│    success: true,    │
│    user: {           │
│      uid: "...",     │
│      mobile: "...",  │
│      name: "...",    │
│      ...             │
│    }                 │
│  }                   │
└──────────────────────┘
```

### Update Profile Fields
```
┌──────────────────────────────────┐
│  PATCH /api/user/profile         │
│  Headers: Bearer <firebase_token>│
│  Body: {                         │
│    name: "Updated Name",         │
│    address: "New Address"        │
│  }                               │
└──────────┬───────────────────────┘
           │
           ▼
┌──────────────────────┐
│  Response:           │
│  {                   │
│    success: true,    │
│    user: {...}       │
│  }                   │
└──────────────────────┘
```

## Error Handling Flow

```
┌──────────────────┐
│   API Call       │
└────────┬─────────┘
         │
    ┌────┴────┐
    │ Success?│
    └────┬────┘
         │
    ┌────┴────┐
    │   Yes   │   No
    │         │
    ▼         ▼
┌────────┐  ┌──────────────────┐
│Process │  │ Show Error       │
│Response│  │ SnackBar         │
└────────┘  │ {                │
            │   success: false,│
            │   message: "..." │
            │ }                │
            └──────────────────┘
```
