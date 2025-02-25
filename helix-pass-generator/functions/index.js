const functions = require("firebase-functions");
const fs = require("fs");
const path = require("path");
const {PKPass} = require("passkit-generator");

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
    const {firstName, lastName, company, jobTitle, cardSlug, cardURL} = req.body;
    
    console.log(`Generating pass for: ${firstName} ${lastName}`);
    
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
      passJson.logoText = templatePassJson.logoText;
      
      // Use template structure for fields but with dynamic content
      passJson.generic = {
        primaryFields: [
          { 
            key: "name", 
            label: templatePassJson.generic?.primaryFields?.[0]?.label || "Name",
            value: `${firstName} ${lastName}`,
          }
        ],
        secondaryFields: company ? [
          { 
            key: "company", 
            label: templatePassJson.generic?.secondaryFields?.[0]?.label || "COMPANY", 
            value: company,
          }
        ] : [],
        auxiliaryFields: jobTitle ? [
          { 
            key: "title", 
            label: templatePassJson.generic?.secondaryFields?.[1]?.label || "TITLE", 
            value: jobTitle,
          }
        ] : []
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
    
    // Create icon@3x.png from icon@2x.png if it doesn't exist
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