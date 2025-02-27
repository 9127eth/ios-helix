const functions = require("firebase-functions");
const fs = require("fs");
const path = require("path");
const {PKPass} = require("passkit-generator");
const axios = require("axios"); // Add axios for HTTP requests
const sharp = require("sharp"); // Add sharp for image processing

// Load certificates
const wwdr = fs.readFileSync(
  path.join(__dirname, "certs", "wwdr.pem")
);
const signerCert = fs.readFileSync(
  path.join(__dirname, "certs", "signerCert.pem")
);
const signerKey = fs.readFileSync(
  path.join(__dirname, "certs", "signerKey.pem")
);
const signerKeyPassphrase = "HelixAlexander5757!"; // Replace with your actual password

// Create a pass template
const MODEL_PATH = path.join(__dirname, "models", "CardTemplate.pass");

// Simple API key for basic security
const API_KEY = "helix-wallet-api-key-12345"; // Change this to something secure

// Add rate limiting with a simple in-memory store based on usernames
// Note: This is reset when the function instance is recycled
const rateLimits = {
  userRequests: {},
  lastResetTime: Date.now()
};

// Rate limit configuration
const RATE_LIMIT = {
  requestsPerUser: 30,    // Maximum requests per username per day
  resetIntervalMs: 86400000, // Reset counter every day (86400000 ms)
};

// Function to check and update rate limits
function checkRateLimit(username) {
  const now = Date.now();
  
  // Reset counters if the interval has passed
  if (now - rateLimits.lastResetTime > RATE_LIMIT.resetIntervalMs) {
    rateLimits.userRequests = {};
    rateLimits.lastResetTime = now;
  }
  
  // Initialize or increment the counter for this user
  rateLimits.userRequests[username] = (rateLimits.userRequests[username] || 0) + 1;
  
  // Check if the user has exceeded the limit
  return rateLimits.userRequests[username] <= RATE_LIMIT.requestsPerUser;
}

exports.generatePassV2 = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type, X-API-Key");
  
  // Handle preflight OPTIONS request
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  
  // Only allow POST requests
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }
  
  // Check API key
  const apiKey = req.headers['x-api-key'];
  if (apiKey !== API_KEY) {
    return res.status(403).json({
      error: "Unauthorized",
      details: "Invalid API key"
    });
  }
  
  try {
    const {firstName, lastName, company, jobTitle, cardSlug, cardURL, description, phoneNumber, email, imageUrl, username} = req.body;
    
    // Ensure username is provided
    if (!username) {
      return res.status(400).json({
        error: "Bad Request",
        details: "Username is required for rate limiting"
      });
    }
    
    console.log(`Generating pass for: ${firstName} ${lastName} (username: ${username})`);
    
    // Apply rate limiting based on username
    if (!checkRateLimit(username)) {
      console.log(`Rate limit exceeded for user: ${username}`);
      return res.status(429).json({
        error: "Too Many Requests",
        details: "You've reached the daily limit for generating wallet passes. Please try again tomorrow."
      });
    }
    
    console.log("Received request with imageUrl:", imageUrl);
    
    // Create pass.json content - keep the critical identifiers
    const passJson = {
      formatVersion: 1,
      passTypeIdentifier: "pass.com.rxradio.helix",
      teamIdentifier: "7544NQ6262", // Keep the team ID
      organizationName: "Helix",
      description: "Helix Business Card",
      serialNumber: cardSlug,
      type: "generic"
    };
    
    // Load design elements from template
    try {
      const templatePassJson = JSON.parse(fs.readFileSync(path.join(MODEL_PATH, "pass.json")));
      
      // Copy design elements from template
      passJson.foregroundColor = templatePassJson.foregroundColor;
      passJson.backgroundColor = templatePassJson.backgroundColor;
      passJson.labelColor = templatePassJson.labelColor;
      
      // Use template structure for fields but with dynamic content
      passJson.generic = {
        // Move description to header fields (top right)
        headerFields: [
          {
            key: "card_description",
            value: description || "Helix Business Card",
            textAlignment: "PKTextAlignmentRight"
          }
        ],
        // Primary field for name with line break to shift it down
        primaryFields: [
          { 
            key: "name", 
            value: `\n${firstName} ${lastName}`,
            textAlignment: "PKTextAlignmentLeft"
          }
        ],
        // Secondary fields for position and company with better spacing around the separator
        secondaryFields: [
          { 
            key: "position_company", 
            value: company && jobTitle ? `${jobTitle}  |  ${company}` : (company || jobTitle || ""),
            textAlignment: "PKTextAlignmentLeft"
          }
        ],
        // Simple auxiliary fields without labels and without line break attempts
        auxiliaryFields: [
          phoneNumber ? {
            key: "phone",
            value: phoneNumber,
            textAlignment: "PKTextAlignmentLeft"
          } : null,
          email ? {
            key: "email",
            value: email,
            textAlignment: "PKTextAlignmentLeft"
          } : null
        ].filter(field => field !== null),
        
        // Simple back fields
        backFields: [
          phoneNumber ? {
            key: "phone_back",
            label: "Phone",
            value: phoneNumber
          } : null,
          email ? {
            key: "email_back",
            label: "Email",
            value: email
          } : null,
          {
            key: "about",
            label: "About This Card",
            value: "This digital business card was created with Helix.\n\nTap the QR code to view the full digital card online."
          }
        ].filter(field => field !== null)
      };
      
      console.log("Successfully loaded design elements from template");
    } catch (error) {
      console.error("Error loading template pass.json:", error);
      // Fallback to default design if template can't be loaded
      passJson.foregroundColor = "rgb(255, 255, 255)";
      passJson.backgroundColor = "rgb(0, 0, 0)";
      passJson.labelColor = "rgb(255, 255, 255)";
      
      passJson.generic = {
        primaryFields: [
          { 
            key: "name", 
            value: `${firstName} ${lastName}`,
          }
        ],
        secondaryFields: company ? [
          { 
            key: "company", 
            label: "COMPANY", 
            value: company,
          }
        ] : [],
        auxiliaryFields: jobTitle ? [
          { 
            key: "title", 
            label: "TITLE", 
            value: jobTitle,
          }
        ] : []
      };
    }
    
    // Add barcode
    passJson.barcodes = [
      {
        message: cardURL,
        format: "PKBarcodeFormatQR",
        messageEncoding: "iso-8859-1"
      }
    ];
    
    // Load existing images from the template directory
    const initialBuffers = {
      "pass.json": Buffer.from(JSON.stringify(passJson))
    };
    
    // Download profile image if available and use as thumbnail
    if (imageUrl && imageUrl.trim() !== "") {
      try {
        console.log(`Downloading profile image from: ${imageUrl}`);
        const imageResponse = await axios.get(imageUrl, { responseType: 'arraybuffer' });
        console.log(`Downloaded image: ${imageResponse.data.length} bytes`);
        
        try {
          // Create a circular version of the image using SVG mask
          // This approach should work with any version of Sharp
          const svgCircle = Buffer.from(`
            <svg width="90" height="90">
              <circle cx="45" cy="45" r="45" fill="white"/>
            </svg>`);
            
          const svgCircle2x = Buffer.from(`
            <svg width="180" height="180">
              <circle cx="90" cy="90" r="90" fill="white"/>
            </svg>`);
          
          // Process standard resolution image
          const thumbnailBuffer = await sharp(Buffer.from(imageResponse.data))
            .resize(90, 90, { fit: 'cover' }) // Resize to square
            .composite([{
              input: svgCircle,
              blend: 'dest-in'
            }])
            .png()
            .toBuffer();
          
          // Process 2x resolution image
          const thumbnail2xBuffer = await sharp(Buffer.from(imageResponse.data))
            .resize(180, 180, { fit: 'cover' }) // Resize to square
            .composite([{
              input: svgCircle2x,
              blend: 'dest-in'
            }])
            .png()
            .toBuffer();
          
          // Add the processed images to the pass
          initialBuffers["thumbnail.png"] = thumbnailBuffer;
          initialBuffers["thumbnail@2x.png"] = thumbnail2xBuffer;
          
          console.log("Successfully created circular thumbnails");
        } catch (sharpError) {
          console.error("Error processing image with Sharp:", sharpError);
          
          // Fallback to using the original image
          initialBuffers["thumbnail.png"] = Buffer.from(imageResponse.data);
          initialBuffers["thumbnail@2x.png"] = Buffer.from(imageResponse.data);
          console.log("Using raw image as thumbnail (fallback after Sharp error)");
        }
      } catch (imageError) {
        console.error("Error downloading profile image:", imageError);
      }
    }
    
    // Load icon.png if it exists
    try {
      initialBuffers["icon.png"] = fs.readFileSync(path.join(MODEL_PATH, "icon.png"));
      console.log("Loaded icon.png from template");
    } catch (error) {
      console.error("Error loading icon.png:", error);
    }
    
    // Load icon@2x.png if it exists
    try {
      initialBuffers["icon@2x.png"] = fs.readFileSync(path.join(MODEL_PATH, "icon@2x.png"));
      console.log("Loaded icon@2x.png from template");
    } catch (error) {
      console.error("Error loading icon@2x.png:", error);
    }
    
    // Load icon@3x.png if it doesn't exist
    try {
      if (fs.existsSync(path.join(MODEL_PATH, "icon@3x.png"))) {
        initialBuffers["icon@3x.png"] = fs.readFileSync(path.join(MODEL_PATH, "icon@3x.png"));
        console.log("Loaded icon@3x.png from template");
      } else if (initialBuffers["icon@2x.png"]) {
        // Use icon@2x.png as icon@3x.png
        initialBuffers["icon@3x.png"] = initialBuffers["icon@2x.png"];
        console.log("Using icon@2x.png as icon@3x.png");
      }
    } catch (error) {
      console.error("Error handling icon@3x.png:", error);
    }
    
    // Load logo.png if it exists
    try {
      initialBuffers["logo.png"] = fs.readFileSync(path.join(MODEL_PATH, "logo.png"));
      console.log("Loaded logo.png from template");
    } catch (error) {
      console.error("Error loading logo.png:", error);
    }
    
    // Load logo@2x.png if it exists
    try {
      initialBuffers["logo@2x.png"] = fs.readFileSync(path.join(MODEL_PATH, "logo@2x.png"));
      console.log("Loaded logo@2x.png from template");
    } catch (error) {
      console.error("Error loading logo@2x.png:", error);
    }
    
    // Load strip.png if it exists
    try {
      initialBuffers["strip.png"] = fs.readFileSync(path.join(MODEL_PATH, "strip.png"));
      console.log("Loaded strip.png from template");
    } catch (error) {
      console.error("Error loading strip.png:", error);
    }
    
    // Load strip@2x.png if it exists
    try {
      initialBuffers["strip@2x.png"] = fs.readFileSync(path.join(MODEL_PATH, "strip@2x.png"));
      console.log("Loaded strip@2x.png from template");
    } catch (error) {
      console.error("Error loading strip@2x.png:", error);
    }
    
    // Log all the buffers we've loaded
    console.log("Loaded buffers:", Object.keys(initialBuffers));
    
    // Create a new PKPass instance with explicit type
    const pass = new PKPass(initialBuffers, {
      wwdr,
      signerCert,
      signerKey,
      signerKeyPassphrase,
    }, {
      // Set type explicitly in props
      type: "generic"
    });
    
    // Generate pass
    const buffer = pass.getAsBuffer();
    
    // Send pass as response
    res.set({
      "Content-Type": "application/vnd.apple.pkpass",
      "Content-disposition": `attachment; filename=${cardSlug}.pkpass`,
    });
    res.send(buffer);
    
    console.log(`Pass generated successfully for: ${firstName} ${lastName}`);
  } catch (error) {
    console.error("Error generating pass:", error);
    res.status(500).json({
      error: "Failed to generate pass", 
      details: error.message,
    });
  }
});