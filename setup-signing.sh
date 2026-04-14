#!/bin/bash

# SKS Mobile App - Signing Setup Script
# This script helps you set up app signing for production builds

set -e  # Exit on error

echo "🔐 SKS Mobile App - Signing Setup"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found!${NC}"
    echo "Please run this script from the SKS-mobile-V2 directory"
    exit 1
fi

# Check if keytool is installed
if ! command -v keytool &> /dev/null; then
    echo -e "${RED}❌ Error: keytool is not installed!${NC}"
    echo "keytool comes with Java JDK. Please install Java JDK first."
    exit 1
fi

# Check if keystore already exists
KEYSTORE_PATH="$HOME/sks-release-key.jks"
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}⚠️  Warning: Keystore already exists at $KEYSTORE_PATH${NC}"
    echo ""
    read -p "Do you want to create a new keystore? This will overwrite the existing one! (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping keystore creation..."
        SKIP_KEYSTORE=true
    else
        echo "Creating new keystore..."
        SKIP_KEYSTORE=false
    fi
else
    SKIP_KEYSTORE=false
fi

# Create keystore
if [ "$SKIP_KEYSTORE" = false ]; then
    echo ""
    echo "📝 Creating keystore..."
    echo ""
    echo -e "${BLUE}You will be asked for the following information:${NC}"
    echo "  - Keystore password (remember this!)"
    echo "  - Key password (can be same as keystore password)"
    echo "  - Your name"
    echo "  - Organization unit (e.g., Development)"
    echo "  - Organization name (e.g., SKS)"
    echo "  - City"
    echo "  - State/Province"
    echo "  - Country code (e.g., IN for India)"
    echo ""
    echo -e "${YELLOW}⚠️  IMPORTANT: Save these passwords securely!${NC}"
    echo ""
    read -p "Press Enter to continue..."
    echo ""
    
    keytool -genkey -v -keystore "$KEYSTORE_PATH" \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias sks-key-alias
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Keystore created successfully!${NC}"
        echo "📍 Location: $KEYSTORE_PATH"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANT:${NC}"
        echo "  - Keep this keystore file safe!"
        echo "  - Never commit it to Git!"
        echo "  - You'll need it for all future app updates!"
        echo "  - If you lose it, you cannot update your app!"
        echo ""
    else
        echo -e "${RED}❌ Failed to create keystore!${NC}"
        exit 1
    fi
fi

# Create key.properties
echo ""
echo "📝 Creating key.properties file..."
echo ""

if [ -f "android/key.properties" ]; then
    echo -e "${YELLOW}⚠️  Warning: android/key.properties already exists!${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping key.properties creation..."
        exit 0
    fi
fi

# Get passwords
echo "Enter keystore password:"
read -s STORE_PASSWORD
echo ""

echo "Enter key password (press Enter to use same as keystore password):"
read -s KEY_PASSWORD
echo ""

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD=$STORE_PASSWORD
fi

# Create key.properties file
cat > android/key.properties << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=sks-key-alias
storeFile=$KEYSTORE_PATH
EOF

echo -e "${GREEN}✅ key.properties created successfully!${NC}"
echo ""

# Add to .gitignore if not already there
if ! grep -q "android/key.properties" .gitignore 2>/dev/null; then
    echo "android/key.properties" >> .gitignore
    echo -e "${GREEN}✅ Added key.properties to .gitignore${NC}"
fi

if ! grep -q "*.jks" .gitignore 2>/dev/null; then
    echo "*.jks" >> .gitignore
    echo -e "${GREEN}✅ Added *.jks to .gitignore${NC}"
fi

# Update build.gradle if needed
echo ""
echo "📝 Checking build.gradle configuration..."

BUILD_GRADLE="android/app/build.gradle"

if ! grep -q "keystoreProperties" "$BUILD_GRADLE"; then
    echo ""
    echo -e "${YELLOW}⚠️  build.gradle needs to be updated!${NC}"
    echo ""
    echo "Please add the following to android/app/build.gradle:"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    cat << 'EOF'

// Add this BEFORE the android { block
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing configuration ...

    // Add this BEFORE buildTypes
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            // Add this line
            signingConfig signingConfigs.release
            
            // ... rest of release config ...
        }
    }
}
EOF
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "See BUILD_PRODUCTION_APK.md for detailed instructions."
else
    echo -e "${GREEN}✅ build.gradle already configured!${NC}"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 What was created:"
echo "  ✅ Keystore: $KEYSTORE_PATH"
echo "  ✅ key.properties: android/key.properties"
echo "  ✅ Updated .gitignore"
echo ""
echo "📝 Next steps:"
echo "  1. Verify build.gradle is configured (see above)"
echo "  2. Update app version in android/app/build.gradle"
echo "  3. Set production environment variables in .env"
echo "  4. Run: ./build-release.sh"
echo ""
echo "📚 For detailed instructions, see:"
echo "  BUILD_PRODUCTION_APK.md"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT REMINDERS:${NC}"
echo "  - Keep your keystore file safe!"
echo "  - Never commit key.properties or keystore to Git!"
echo "  - Save your passwords in a secure password manager!"
echo "  - You'll need the keystore for all future updates!"
echo ""
