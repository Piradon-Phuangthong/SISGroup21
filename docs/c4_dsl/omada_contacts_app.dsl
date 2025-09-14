workspace "Omada Contacts App" "C4 model for the Omada contacts management application with offline-first architecture and sharing capabilities" {

    model {
        # Actors
        user = person "User" "A person who manages and shares contacts using the mobile app"
        
        # Main System
        omadaContactsApp = softwareSystem "Omada Contacts App" "Offline-first Flutter mobile application for managing contacts with sharing capabilities" {
            
            # Mobile App Container
            mobileApp = container "Mobile Application" "Flutter mobile app for contact management" "Flutter, Dart" {
                # Core Services
                authService = component "Authentication Service" "User authentication and profile management" "Dart Service"
                contactService = component "Contact Service" "Contact CRUD operations and search" "Dart Service"
                sharingService = component "Sharing Service" "Contact sharing with permissions" "Dart Service"
                
                # UI Layer
                contactsScreen = component "Contacts Screen" "Main contact interface with filtering" "Flutter UI"
                
                # Infrastructure
                supabaseClient = component "Supabase Client" "Cloud backend integration" "Dart Service"
            }
            
            # Local Storage
            localDatabase = container "Local Database" "Offline contact storage" "SQLite" "Database"
            
            # Supabase Backend Container
            supabaseBackend = container "Supabase Backend" "Cloud backend services" "Supabase" {
                # Core Services
                authSystem = component "Authentication System" "User authentication with JWT" "Supabase Auth"
                database = component "PostgreSQL Database" "Contact data with real-time sync" "PostgreSQL"
                fileStorage = component "File Storage" "Avatar and attachment storage" "Supabase Storage"
                
                # Database Tables
                profilesTable = component "Profiles Table" "User profiles and usernames" "Table"
                contactsTable = component "Contacts Table" "Contact information" "Table"
                sharingTable = component "Sharing Table" "Share requests and permissions" "Table"
            }
        }
        
        # High-level Relationships
        user -> omadaContactsApp "Manages contacts and shares with others"
        
        # Container Relationships
        mobileApp -> localDatabase "Offline storage" "SQLite"
        mobileApp -> supabaseBackend "Cloud sync and auth" "HTTPS/WebSocket"
        
        # Component Relationships - Mobile App
        contactsScreen -> authService "Authentication"
        contactsScreen -> contactService "Contact management"
        contactsScreen -> sharingService "Contact sharing"
        
        authService -> supabaseClient "Auth operations"
        contactService -> supabaseClient "Contact CRUD"
        contactService -> localDatabase "Offline storage"
        sharingService -> supabaseClient "Sharing operations"
        
        # Component Relationships - Supabase Backend
        supabaseClient -> authSystem "User authentication"
        supabaseClient -> database "Data operations"
        supabaseClient -> fileStorage "File operations"
        supabaseClient -> profilesTable "User profile operations"
        supabaseClient -> contactsTable "Contact operations"
        supabaseClient -> sharingTable "Sharing operations"
    }
    
    views {
        # System Context Diagram
        systemContext omadaContactsApp "SystemContext" {
            include *
            autoLayout
        }
        
        # Container Diagram
        container omadaContactsApp "Containers" {
            include *
            autoLayout
        }
        
        # Mobile App Components
        component mobileApp "MobileAppComponents" {
            include *
            autoLayout
        }
        
        # Supabase Backend Components
        component supabaseBackend "SupabaseBackendComponents" {
            include *
            autoLayout
        }
        
        # Dynamic Views - Simplified
        
        # User Authentication
        dynamic mobileApp "Authentication" "User login process" {
            contactsScreen -> authService "Login request"
            authService -> supabaseClient "Authenticate"
            supabaseClient -> authSystem "Verify credentials"
            authSystem -> supabaseClient "Return token"
            supabaseClient -> authService "Authenticated"
            authService -> contactsScreen "Login success"
            autoLayout
        }
        
        # Contact Management
        dynamic mobileApp "ContactManagement" "Creating and syncing contacts" {
            contactsScreen -> contactService "Create contact"
            contactService -> localDatabase "Store offline"
            contactService -> supabaseClient "Sync to cloud"
            supabaseClient -> contactsTable "Save contact"
            contactsTable -> supabaseClient "Confirm save"
            supabaseClient -> contactService "Sync complete"
            contactService -> contactsScreen "Update UI"
            autoLayout
        }
        
        # Contact Sharing
        dynamic mobileApp "ContactSharing" "Sharing contacts with permissions" {
            contactsScreen -> sharingService "Share contact"
            sharingService -> supabaseClient "Create share request"
            supabaseClient -> sharingTable "Store share permissions"
            sharingTable -> supabaseClient "Share created"
            supabaseClient -> sharingService "Share confirmed"
            sharingService -> contactsScreen "Share complete"
            autoLayout
        }
        
        # Styling
        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #1168bd
                color #ffffff
            }
            element "Flutter UI" {
                background #42a5f5
                color #ffffff
            }
            element "Dart Service" {
                background #13518c
                color #ffffff
            }
            element "Supabase" {
                background #52b788
                color #ffffff
            }
        }
        
        themes default
    }
    
}
