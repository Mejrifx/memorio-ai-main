// Email templates for Memorio invitations

export const directorInviteTemplate = (email: string, tempPassword: string, orgName: string) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: 'Dosis', Arial, sans-serif;
      background-color: #f4e8de;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #fff3e9;
      border: 3px solid #436481;
      border-radius: 20px;
      padding: 40px;
      box-shadow: 0 2px 8px -2px rgba(0,0,0,0.2);
    }
    .header {
      text-align: center;
      color: #32343a;
      font-size: 32px;
      margin-bottom: 20px;
    }
    .content {
      color: #32343a;
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .credentials {
      background-color: #f4e8de;
      border-radius: 10px;
      padding: 20px;
      margin: 20px 0;
    }
    .button {
      display: inline-block;
      background-color: #32343a;
      color: #f2eadd !important;
      padding: 15px 30px;
      border-radius: 60px;
      text-decoration: none;
      text-transform: uppercase;
      letter-spacing: 2px;
      font-weight: 600;
      transition: all 0.3s ease;
    }
    .button:hover {
      color: #6ca7d3 !important;
      text-shadow: 0 3px 6px rgba(108, 167, 211, 0.24);
    }
    .footer {
      text-align: center;
      color: #33333373;
      font-size: 14px;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">Welcome to Memorio</h1>
    <div class="content">
      <p>You've been invited to manage funeral home cases for <strong>${orgName}</strong> on Memorio.</p>
      <p>As a Director, you'll be able to create cases, invite families, and manage the tribute creation process.</p>
      
      <div class="credentials">
        <p><strong>Email:</strong> ${email}</p>
        <p><strong>Temporary Password:</strong> ${tempPassword}</p>
      </div>
      
      <p style="color: #6ca7d3; font-weight: bold;">⚠️ Please login and change your password immediately for security.</p>
      
      <div style="text-align: center; margin-top: 30px;">
        <a href="https://memorio.ai/director/login" class="button">Login Now</a>
      </div>
    </div>
    
    <div class="footer">
      <p>If you didn't expect this invitation, please ignore this email.</p>
      <p>© 2025 Memorio. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
`;

export const familyInviteTemplate = (name: string, deceasedName: string, magicLink: string, directorName: string) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: 'Dosis', Arial, sans-serif;
      background-color: #f4e8de;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #fff3e9;
      border: 3px solid #436481;
      border-radius: 20px;
      padding: 40px;
      box-shadow: 0 2px 8px -2px rgba(0,0,0,0.2);
    }
    .header {
      text-align: center;
      color: #32343a;
      font-size: 32px;
      margin-bottom: 20px;
    }
    .content {
      color: #32343a;
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .highlight {
      background-color: #f4e8de;
      border-radius: 10px;
      padding: 20px;
      margin: 20px 0;
      text-align: center;
    }
    .button {
      display: inline-block;
      background-color: #32343a;
      color: #f2eadd !important;
      padding: 15px 30px;
      border-radius: 60px;
      text-decoration: none;
      text-transform: uppercase;
      letter-spacing: 2px;
      font-weight: 600;
      transition: all 0.3s ease;
    }
    .button:hover {
      color: #6ca7d3 !important;
      text-shadow: 0 3px 6px rgba(108, 167, 211, 0.24);
    }
    .footer {
      text-align: center;
      color: #33333373;
      font-size: 14px;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">Memorial Tribute Invitation</h1>
    <div class="content">
      <p>Dear ${name},</p>
      <p>You've been invited by ${directorName} to create a meaningful tribute for <strong>${deceasedName}</strong>.</p>
      
      <div class="highlight">
        <p style="font-size: 18px; font-weight: 600; margin: 0;">Create a Tribute for</p>
        <p style="font-size: 24px; color: #436481; font-weight: 700; margin: 10px 0;">${deceasedName}</p>
      </div>
      
      <p>Take your time—each question helps us gently piece together a heartfelt memory. There's no rush.</p>
      
      <p style="color: #6ca7d3; font-weight: bold;">🔒 This link is secure and only accessible to you. It will expire in 24 hours.</p>
      
      <div style="text-align: center; margin-top: 30px;">
        <a href="${magicLink}" class="button">Start Creating Tribute</a>
      </div>
    </div>
    
    <div class="footer">
      <p>If you didn't expect this invitation, please contact ${directorName}.</p>
      <p>© 2025 Memorio. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
`;

export const passwordResetTemplate = (resetLink: string) => `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: 'Dosis', Arial, sans-serif;
      background-color: #f4e8de;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #fff3e9;
      border: 3px solid #436481;
      border-radius: 20px;
      padding: 40px;
      box-shadow: 0 2px 8px -2px rgba(0,0,0,0.2);
    }
    .header {
      text-align: center;
      color: #32343a;
      font-size: 32px;
      margin-bottom: 20px;
    }
    .content {
      color: #32343a;
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 30px;
    }
    .button {
      display: inline-block;
      background-color: #32343a;
      color: #f2eadd !important;
      padding: 15px 30px;
      border-radius: 60px;
      text-decoration: none;
      text-transform: uppercase;
      letter-spacing: 2px;
      font-weight: 600;
    }
    .footer {
      text-align: center;
      color: #33333373;
      font-size: 14px;
      margin-top: 30px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1 class="header">Reset Your Password</h1>
    <div class="content">
      <p>You've requested to reset your Memorio password.</p>
      <p>Click the button below to create a new password. This link will expire in 1 hour.</p>
      
      <div style="text-align: center; margin-top: 30px;">
        <a href="${resetLink}" class="button">Reset Password</a>
      </div>
      
      <p style="color: #33333373; margin-top: 30px;">If you didn't request this reset, please ignore this email and your password will remain unchanged.</p>
    </div>
    
    <div class="footer">
      <p>© 2025 Memorio. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
`;

