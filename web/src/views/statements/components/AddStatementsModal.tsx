import React, { useState, useEffect } from 'react';
import {
  CModal,
  CModalHeader,
  CModalTitle,
  CModalBody,
  CModalFooter,
  CFormInput,
  CMultiSelect,
  CButton,
  CInputGroupText,
  CInputGroup,
  CFormSelect,
  CAlert,
} from '@coreui/react-pro';
import { Client, DatabaseService } from 'src/db/database';
import { EditAssetsSection } from 'src/components/EditAssetsSection';
import { ref, uploadBytes } from 'firebase/storage';
import { getStorage } from 'firebase/storage';
import config from '../../../../config.json'

interface AddStatementModalProps {
  visible: boolean;
  onClose: () => void;
  onUploadSuccess: () => void;
}

export const AddStatementModal: React.FC<AddStatementModalProps> = ({
  visible,
  onClose,
  onUploadSuccess,
}) => {
  const db = new DatabaseService();

  const [searchTerm, setSearchTerm] = useState('');
  const [clients, setClients] = useState<Client[]>([]);
  const [filteredClients, setFilteredClients] = useState<Client[]>([]);
  const [selectedClient, setSelectedClient] = useState<string>('');
  const [files, setFiles] = useState<File[]>([]);
  const [uploading, setUploading] = useState(false);
  const [isRecipientSameAsClient, setIsRecipientSameAsClient] = useState<boolean>(true);
  const [activityState, setActivityState] = useState<any>({}); // Define appropriate type
  const [clientState, setClientState] = useState<Client | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    const fetchClients = async () => {
      const fetchedClients = await db.getClients();
      setClients(fetchedClients);
      setFilteredClients(fetchedClients);
    };
    fetchClients();
  }, []);

  useEffect(() => {
    const filtered = clients.filter(
      (client) =>
        (client.firstName?.toLowerCase().includes(searchTerm.toLowerCase()) || client.lastName.toLowerCase().includes(searchTerm.toLowerCase())) ?? false
    );
    setFilteredClients(filtered);
  }, [searchTerm, clients]);

  const clientOptions = clients.map((client) => ({
    label: `${client.firstName} ${client.lastName}`,
    value: client.cid,
  }));

  const handleClientChange = async (selectedValue: { label: string; value: string | number }[]) => {
    const singleSelection = selectedValue.slice(0, 1);
    if (singleSelection.length === 0) {
      setClientState(await db.getClient(activityState.parentDocId ?? ''));
    } else {
      const client = singleSelection[0].label as string;
      const cid = singleSelection[0].value as string;
      console.log(cid);
      setClientState(await db.getClient(cid) ?? await db.getClient(activityState.parentDocId ?? ''));

      if (isRecipientSameAsClient) {
        setActivityState({ ...activityState, recipient: client });
      }
    }
  };

  const handleUpload = async () => {
    if (!clientState || !clientState.cid) {
      setErrorMessage('Please select a client.');
      return;
    }

    if (files.length === 0) {
      setErrorMessage('Please select at least one file.');
      return;
    }

    setErrorMessage(null); // Clear any existing error messages
    await uploadFiles();
  };

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (event.target.files) {
      setFiles(Array.from(event.target.files));
    }
  };

  const uploadFiles = async () => {
    if (!clientState || !clientState.cid) {
      console.error('No client selected.');
      return;
    }

    if (files.length === 0) {
      console.error('No files to upload.');
      return;
    }

    setUploading(true);
    const cid = clientState.cid;
    const uploadPromises = files.map((file) => {
      const storagePath = `${config.FIRESTORE_ACTIVE_USERS_COLLECTION}/${cid}/${file.name}`;
      console.log(`Uploading file to: ${storagePath}`);
      const storageRef = ref(getStorage(), storagePath);
      return uploadBytes(storageRef, file);
    });

    try {
      await Promise.all(uploadPromises);
      console.log('All files uploaded successfully.');
      onUploadSuccess();
      setFiles([]);
    } catch (error) {
      console.error('Error uploading files:', error);
    } finally {
      setUploading(false);
    }
  };

  return (
    <CModal visible={visible} onClose={onClose}>
      <CModalHeader closeButton>
        <CModalTitle>Add Statement</CModalTitle>
      </CModalHeader>
      <CModalBody>
        <CMultiSelect
          options={clientOptions}
          onChange={handleClientChange}
          placeholder="Select Client"
          multiple={false}
        />
      
        <div className="mb-3 mt-3"> {/* Added margin-top class */}
          <CFormInput
            type="file"
            accept=".pdf"
            multiple
            onChange={handleFileChange}
          />
          {files.length > 0 && (
            <div style={{ marginTop: '10px' }}>
              <strong>Selected files:</strong>
              <ul>
                {files.map((file) => (
                  <li key={file.name}>{file.name}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
        {errorMessage && (
          <CAlert color="danger">
            {errorMessage}
          </CAlert>
        )}
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" onClick={onClose} disabled={uploading}>
          Cancel
        </CButton>
        <CButton color="primary" onClick={handleUpload} disabled={uploading}>
          {uploading ? 'Uploading...' : 'Upload'}
        </CButton>
      </CModalFooter>
    </CModal>
  );
};

export default AddStatementModal;