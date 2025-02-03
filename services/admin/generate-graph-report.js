const admin = require('firebase-admin');
const path = require('path');
const PDFDocument = require('pdfkit');
const fs = require('fs');

// Path to the service account key file
const serviceAccountPath = path.join(__dirname, 'team-shaikh-service-account.json');
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

/**
 * Adds left-aligned text to the PDF document.
 *
 * @param {PDFDocument} doc - The PDFDocument instance.
 * @param {string} text - The text to add.
 * @param {number} fontSize - The font size for the text.
 */
function addLeftAlignedText(doc, text, fontSize) {
  doc.font('Helvetica') // Ensure the correct font is set
     .fontSize(fontSize)
     .text(text, doc.page.margins.left, doc.y, { align: 'left', continued: false });
  doc.moveDown(); // Moves down to avoid overlapping
}

/**
 * Formats a number as USD currency.
 *
 * @param {number} value - The number to format.
 * @returns {string} - The formatted currency string.
 */
const formatUSD = (value) => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
  }).format(value);
};

/**
 * Generates a graphpoint PDF report for all users in the specified collection.
 *
 * @param {string} usersCollectionName - The name of the users collection.
 */
async function generateGraphpointReport(usersCollectionName) {
  console.log(`Starting graphpoint report generation for collection '${usersCollectionName}'`);

  const usersRef = db.collection(usersCollectionName);

  try {
    const usersSnapshot = await usersRef.get();
    console.log(`Found ${usersSnapshot.size} users in collection '${usersCollectionName}'`);

    // Sort users alphabetically by first and last name
    const sortedUsers = usersSnapshot.docs.sort((a, b) => {
      const nameA = `${a.data().name.first} ${a.data().name.last}`.toLowerCase();
      const nameB = `${b.data().name.first} ${b.data().name.last}`.toLowerCase();
      if (nameA < nameB) return -1;
      if (nameA > nameB) return 1;
      return 0;
    });

    // Create a new PDF document
    const doc = new PDFDocument({ margin: 30, size: 'A4' });

    // Pipe the PDF into a writable stream
    const outputFilePath = path.join(__dirname, 'graphpoint_report.pdf');
    const writeStream = fs.createWriteStream(outputFilePath);
    doc.pipe(writeStream);

    // Define default font
    doc.font('Helvetica');

    // Process each user sequentially
    let firstUser = true; // Flag to handle page addition
    for (const userDoc of sortedUsers) { // Use sortedUsers instead of usersSnapshot.docs
      const cid = userDoc.id;
      const userData = userDoc.data();
      const userName = `${userData.name.first} ${userData.name.last}`;
      console.log(`Processing user CID: ${cid}, Name: ${userName}`);

      const userRef = usersRef.doc(cid);
      const graphpointsRef = userRef.collection('graphpoints');

      // Retrieve all graphpoints
      const graphpointsSnapshot = await graphpointsRef.get();
      if (graphpointsSnapshot.empty) {
        console.log(`No graphpoints found for user CID: ${cid}`);
        continue;
      }

      // Group graphpoints by fund, then by account
      const graphpointsByFund = {};
      graphpointsSnapshot.docs.forEach((doc) => {
        const gp = doc.data();
        const fundName = gp.fund || 'Unspecified';
        if (!graphpointsByFund[fundName]) {
          graphpointsByFund[fundName] = {};
        }
        if (!graphpointsByFund[fundName][gp.account]) {
          graphpointsByFund[fundName][gp.account] = [];
        }
        graphpointsByFund[fundName][gp.account].push(gp);
      });

      // Sort fund names (place 'Unspecified' last for clarity)
      const sortedFunds = Object.keys(graphpointsByFund).sort((a, b) => {
        if (a === 'Unspecified') return 1;
        if (b === 'Unspecified') return -1;
        return a.localeCompare(b);
      });

      // Add a new page for each user (except the first one)
      if (!firstUser) {
        doc.addPage();
        console.log(`Added new page for user CID: ${cid}`);

        // Reset font and alignment after adding a new page
        doc.font('Helvetica');
      } else {
        firstUser = false;
      }

      // Set alignment and reset font before writing user heading
      console.log(`Adding user heading for ${userName} with alignment 'left'`);
      addLeftAlignedText(doc, userName, 20);

      // For each fund, display a subheading and its accounts
      for (const fund of sortedFunds) {
        addLeftAlignedText(doc, `Fund: ${fund}`, 16);

        const accountsInFund = Object.keys(graphpointsByFund[fund]).sort((a, b) => {
          if (a.toLowerCase() === 'cumulative') return -1;
          if (b.toLowerCase() === 'cumulative') return 1;
          return a.localeCompare(b);
        });

        for (const account of accountsInFund) {
          const gps = graphpointsByFund[fund][account];
          addLeftAlignedText(doc, `Account: ${account}`, 14);

          // Sort graphpoints by time
          gps.sort((a, b) => a.time.toDate().getTime() - b.time.toDate().getTime());

          // Prepare table data
          const tableHeaders = ['Time', 'Amount', 'Cashflow'];
          const tableRows = gps.map((gp) => [
            gp.time.toDate().toLocaleString(),
            formatUSD(gp.amount),
            formatUSD(gp.cashflow),
          ]);

          // Draw the table using the updated drawTable function
          drawTable(doc, tableHeaders, tableRows);
          doc.moveDown();
        }
      }

      console.log(`Completed report generation for user CID: ${cid}`);
    }

    // Finalize the PDF and end the stream
    doc.end();

    // Wait for the PDF to be written to the file
    await new Promise((resolve, reject) => {
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });

    console.log(`Graphpoint report generated successfully at ${outputFilePath}`);
  } catch (error) {
    console.error(`Error generating graphpoint report for collection '${usersCollectionName}':`, error);
    throw error;
  }
}

/**
 * Draws a table on the PDF document.
 *
 * @param {PDFDocument} doc - The PDFDocument instance.
 * @param {string[]} headers - The table headers.
 * @param {string[][]} rows - The table rows.
 */
function drawTable(doc, headers, rows) {
  const rowHeight = 20;
  const columnCount = headers.length;
  const columnWidth =
    (doc.page.width - doc.page.margins.left - doc.page.margins.right) / columnCount;

  // Initialize the starting y position
  let y = doc.y;

  /**
   * Draws a single row on the PDF.
   *
   * @param {string[]} rowData - The data for each cell in the row.
   * @param {boolean} isHeader - Indicates if the row is a header.
   * @param {number} yPosition - The y position to draw the row.
   */
  const drawRow = (rowData, isHeader, yPosition) => {
    // Set font and size based on row type
    doc.font(isHeader ? 'Helvetica-Bold' : 'Helvetica').fontSize(isHeader ? 12 : 10);

    // Calculate the starting X position
    let x = doc.page.margins.left;

    // Draw each cell in the row
    rowData.forEach((cell) => {
      doc.text(cell, x, yPosition, {
        width: columnWidth,
        align: 'left', // Ensure left alignment
        continued: false,
      });
      x += columnWidth;
    });
  };

  /**
   * Ensures there's enough space to draw a row. If not, adds a new page and redraws the headers.
   *
   * @param {number} requiredHeight - The height required to draw the row.
   */
  const ensureSpace = (requiredHeight) => {
    if (y + requiredHeight > doc.page.height - doc.page.margins.bottom) {
      doc.addPage();
      y = doc.page.margins.top;

      console.log(`Added new page while drawing table. Redrawing headers.`);
      // Redraw the table headers on the new page with left alignment
      drawRow(headers, true, y);
      y += rowHeight;
    }
  };

  // Initial Check Before Drawing Headers
  ensureSpace(rowHeight);

  // Draw the table header with left alignment
  drawRow(headers, true, y);
  y += rowHeight;

  // Draw each table row
  rows.forEach((row) => {
    // Ensure there's enough space for the row
    ensureSpace(rowHeight);

    // Draw the current row with left alignment
    drawRow(row, false, y);
    y += rowHeight;
  });

  // Update the document's y position
  doc.y = y + 5; // Adding a small space after the table

  // Reset alignment to left after drawing the table
  doc.font('Helvetica'); // Ensure font is reset
}

// Example usage
const usersCollectionName = 'playground'; // Replace with your actual users collection name
generateGraphpointReport(usersCollectionName)
  .then(() => {
    console.log('Graphpoint report generation completed successfully');
    process.exit(0); // Exit successfully
  })
  .catch((error) => {
    console.error('Graphpoint report generation failed:', error);
    process.exit(1); // Exit with failure
  });