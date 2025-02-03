import React, { useEffect, useState } from 'react';
import '@coreui/icons/css/all.min.css'; // Ensure this import is present
import {
  CContainer,
  CSmartTable,
  CSpinner,
  CButton,
  CModal,
  CModalHeader,
  CModalBody,
  CModalTitle,
} from '@coreui/react-pro';
import { getStorage, ref, listAll, getMetadata, getDownloadURL, deleteObject } from 'firebase/storage';
import { DatabaseService, Client } from 'src/db/database.ts';
import config from '../../../../config.json';

// Import CoreUI Icons
import CIcon from '@coreui/icons-react';
import { cilTrash, cilSearch } from '@coreui/icons';

interface Document {
  clientName: string;
  documentTitle: string;
  dateAdded: string;
  downloadURL: string;
  storagePath: string;
}

const ClientStatementsPage = () => {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const [isPreviewOpen, setIsPreviewOpen] = useState<boolean>(false);

  useEffect(() => {
    const fetchDocuments = async () => {
      try {
        // Fetch all clients
        const db = new DatabaseService();
        const clients: Client[] = await db.getClients();
        console.log('Fetched clients:', clients.length);

        const storage = getStorage();

        // Create an array of promises to fetch documents for each client
        const clientPromises = clients.map(async (client) => {
          const cid = client.cid;

          // Reference to the client's documents folder
          const listRef = ref(storage, `${config.FIRESTORE_ACTIVE_USERS_COLLECTION}/${cid}/`);

          try {
            // List all items in the folder
            const res = await listAll(listRef);

            if (res.items.length === 0) {
              return []; // Return empty array if no documents
            }

            // Fetch documents for this client
            const documentPromises = res.items.map(async (itemRef) => {
              const metadata = await getMetadata(itemRef);
              const downloadURL = await getDownloadURL(itemRef);

              const document: Document = {
                clientName: `${client.firstName} ${client.lastName}`,
                documentTitle: metadata.name,
                dateAdded: metadata.timeCreated,
                downloadURL: downloadURL,
                storagePath: itemRef.fullPath, // Store the path to delete the file later
              };

              return document;
            });

            // Wait for all documents of this client
            const clientDocuments = await Promise.all(documentPromises);
            return clientDocuments;
          } catch (error) {
            console.error(`Error fetching documents for CID ${cid}:`, error);
            return []; // Return empty array on error
          }
        });

        // Wait for all clients' documents
        const allDocumentsArrays = await Promise.all(clientPromises);

        // Flatten the array of arrays into a single array
        const documentsData = allDocumentsArrays.flat();

        // Sort documents by dateAdded, newest first
        documentsData.sort(
          (a, b) => new Date(b.dateAdded).getTime() - new Date(a.dateAdded).getTime()
        );

        console.log('Total documents fetched:', documentsData.length);
        console.log('Documents:', documentsData);

        setDocuments(documentsData);
        setIsLoading(false);
      } catch (error) {
        console.error('Error fetching documents:', error);
        setIsLoading(false);
      }
    };

    fetchDocuments();
  }, []);

  const handlePreview = (document: Document) => {
    setSelectedDocument(document);
    setIsPreviewOpen(true);
  };

  const handleDelete = async (document: Document) => {
    const confirmDelete = window.confirm(
      `Are you sure you want to delete ${document.documentTitle}?`
    );
    if (!confirmDelete) return;

    try {
      const storage = getStorage();
      const fileRef = ref(storage, document.storagePath);
      await deleteObject(fileRef);
      // Remove the document from the list
      setDocuments((prevDocuments) =>
        prevDocuments.filter((s) => s.storagePath !== document.storagePath)
      );
      alert('File deleted successfully.');
    } catch (error) {
      console.error('Error deleting file:', error);
      alert('Failed to delete the file.');
    }
  };

  if (isLoading) {
    return (
      <div className="text-center">
        <CSpinner color="primary" />
      </div>
    );
  }

  const columns = [
    { key: 'clientName', label: 'Client', _style: { width: '20%' } },
    { key: 'documentTitle', label: 'Document Title', _style: { width: '40%' } },
    { key: 'dateAdded', label: 'Date Added', _style: { width: '15%' }, sorter: true },
    { key: 'actions', label: 'Quick Actions', _style: { width: '10%' }, filter: false },
  ];

  const items = documents.map((document) => ({
    ...document,
    dateAdded: new Date(document.dateAdded).toLocaleDateString(),
  }));

  console.log('Items to display:', items);

  return (
    <CContainer>
      <CSmartTable
        items={items}
        columns={columns}
        columnSorter
        columnFilter
        itemsPerPage={50}
        pagination
        scopedColumns={{
          actions: (item: any) => (
            <td>
              <CButton
                color="info"
                variant="ghost"
                size="sm"
                className="mr-2"
                onClick={() => handlePreview(item)}
              >
                <CIcon icon={cilSearch} size="lg" />
              </CButton>
              <CButton
                color="danger"
                variant="ghost"
                size="sm"
                onClick={() => handleDelete(item)}
              >
                <CIcon icon={cilTrash} size="lg" />
              </CButton>
            </td>
          ),
        }}
        tableProps={{ striped: true, hover: true }}
      />

      {/* Preview Modal */}
      <CModal size="xl" visible={isPreviewOpen} onClose={() => setIsPreviewOpen(false)}>
        <CModalHeader closeButton>
          <CModalTitle>{selectedDocument?.documentTitle}</CModalTitle>
        </CModalHeader>
        <CModalBody>
          {selectedDocument && (
            <iframe
              src={selectedDocument.downloadURL}
              title="Document Preview"
              style={{ width: '100%', height: '80vh' }}
            ></iframe>
          )}
        </CModalBody>
      </CModal>
    </CContainer>
  );
};

export default ClientStatementsPage;