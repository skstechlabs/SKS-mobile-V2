/**
 * Translation Verification Script
 * Checks if Telugu translations have all the keys from English
 */

const fs = require('fs');
const path = require('path');

// Read translation files
const enPath = path.join(__dirname, 'assets', 'translations', 'en.json');
const tePath = path.join(__dirname, 'assets', 'translations', 'te.json');

console.log('🔍 Verifying Translation Files...\n');
console.log('═'.repeat(80));

try {
  // Load English translations
  const enContent = fs.readFileSync(enPath, 'utf8');
  const enTranslations = JSON.parse(enContent);
  const enKeys = Object.keys(enTranslations);
  
  console.log(`✅ English (en.json): ${enKeys.length} keys`);
  
  // Load Telugu translations
  const teContent = fs.readFileSync(tePath, 'utf8');
  const teTranslations = JSON.parse(teContent);
  const teKeys = Object.keys(teTranslations);
  
  console.log(`✅ Telugu (te.json): ${teKeys.length} keys`);
  console.log('═'.repeat(80));
  
  // Find missing keys in Telugu
  const missingInTelugu = enKeys.filter(key => !teKeys.includes(key));
  
  // Find extra keys in Telugu (not in English)
  const extraInTelugu = teKeys.filter(key => !enKeys.includes(key));
  
  // Find empty translations in Telugu
  const emptyInTelugu = teKeys.filter(key => {
    const value = teTranslations[key];
    return !value || value.trim() === '';
  });
  
  console.log('\n📊 Analysis Results:\n');
  
  if (missingInTelugu.length === 0) {
    console.log('✅ All English keys are present in Telugu');
  } else {
    console.log(`❌ Missing in Telugu (${missingInTelugu.length} keys):`);
    missingInTelugu.forEach(key => {
      console.log(`   - ${key}: "${enTranslations[key]}"`);
    });
  }
  
  if (extraInTelugu.length === 0) {
    console.log('✅ No extra keys in Telugu');
  } else {
    console.log(`\n⚠️  Extra keys in Telugu (${extraInTelugu.length} keys):`);
    extraInTelugu.forEach(key => {
      console.log(`   - ${key}: "${teTranslations[key]}"`);
    });
  }
  
  if (emptyInTelugu.length === 0) {
    console.log('✅ No empty translations in Telugu');
  } else {
    console.log(`\n❌ Empty translations in Telugu (${emptyInTelugu.length} keys):`);
    emptyInTelugu.forEach(key => {
      console.log(`   - ${key}`);
    });
  }
  
  console.log('\n' + '═'.repeat(80));
  
  // Summary
  const totalIssues = missingInTelugu.length + emptyInTelugu.length;
  
  if (totalIssues === 0) {
    console.log('✅ SUCCESS: All translations are complete!');
    console.log('✅ Telugu has all required keys with values');
    process.exit(0);
  } else {
    console.log(`❌ ISSUES FOUND: ${totalIssues} translation issues need attention`);
    console.log('   Please fix the missing or empty translations above');
    process.exit(1);
  }
  
} catch (error) {
  console.error('❌ Error reading translation files:', error.message);
  process.exit(1);
}
