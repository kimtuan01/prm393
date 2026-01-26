const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const nodemailer = require("nodemailer");

// Set global options
setGlobalOptions({maxInstances: 10});

// Configure email transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "hkkhanhpro@gmail.com",
    pass: "mhjw ppzf mmxp cerc", // Gmail App Password
  },
});

/**
 * Cloud Function: Send OTP Email
 * Call from Flutter app to send OTP verification email
 */
exports.sendOTP = onCall(async (request) => {
  const {email, otp} = request.data;

  // Validate input
  if (!email || !otp) {
    logger.error("Missing email or OTP", {email, otp});
    throw new Error("Email and OTP are required");
  }

  logger.info("Sending OTP email", {email, otp});

  try {
    // Email options
    const mailOptions = {
      from: "FinTracker <hkkhanhpro@gmail.com>",
      to: email,
      subject: "Mã OTP Xác Thực - FinTracker",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #4ECDC4 0%, #44A08D 100%); padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
            <h1 style="color: white; margin: 0; font-size: 28px;">FinTracker</h1>
            <p style="color: white; margin: 10px 0 0 0; font-size: 14px;">Smart Spend, Bright Future</p>
          </div>
          
          <div style="background: #f9f9f9; padding: 40px 30px; border-radius: 0 0 10px 10px;">
            <h2 style="color: #333; margin: 0 0 20px 0;">Mã OTP Xác Thực</h2>
            <p style="color: #666; font-size: 16px; line-height: 1.6;">Xin chào,</p>
            <p style="color: #666; font-size: 16px; line-height: 1.6;">Mã OTP để xác thực tài khoản FinTracker của bạn là:</p>
            
            <div style="background: white; padding: 30px; text-align: center; border-radius: 10px; margin: 30px 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
              <div style="font-size: 48px; font-weight: bold; color: #4ECDC4; letter-spacing: 15px; font-family: 'Courier New', monospace;">
                ${otp}
              </div>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 5px;">
              <p style="color: #856404; margin: 0; font-size: 14px;">
                ⏰ Mã này có hiệu lực trong <strong>5 phút</strong>.
              </p>
            </div>
            
            <p style="color: #999; font-size: 14px; margin-top: 30px;">
              Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này hoặc liên hệ với chúng tôi nếu bạn nghĩ có điều gì đó không đúng.
            </p>
            
            <hr style="border: none; border-top: 1px solid #e0e0e0; margin: 30px 0;">
            
            <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
              © 2025 FinTracker. All rights reserved.<br>
              Đây là email tự động, vui lòng không trả lời email này.
            </p>
          </div>
        </div>
      `,
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);
    logger.info("Email sent successfully", {messageId: info.messageId});

    return {
      success: true,
      message: "OTP email sent successfully",
      messageId: info.messageId,
    };
  } catch (error) {
    logger.error("Error sending email", {error: error.message});
    throw new Error(`Failed to send email: ${error.message}`);
  }
});
