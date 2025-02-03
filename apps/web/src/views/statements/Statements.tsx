// Statements.tsx

import React, { useState } from 'react';
import { CContainer, CButton } from "@coreui/react-pro";
import { Routes, Route } from 'react-router-dom';
import ClientStatementsPage from './components/ClientStatementsPage';
import AddStatementModal from './components/AddStatementsModal';

const Statements: React.FC = () => {
  const [isAddModalVisible, setIsAddModalVisible] = useState<boolean>(false);

  const handleOpenModal = () => {
    setIsAddModalVisible(true);
  };

  const handleCloseModal = () => {
    setIsAddModalVisible(false);
  };

  const handleUploadSuccess = () => {
    // You can implement additional logic here, such as refreshing the statements list
    setIsAddModalVisible(false);
    // Optionally, you can trigger a refresh in ClientStatementsPage via a shared state or context
    // For simplicity, you might reload the page or implement a callback
    window.location.reload();
  };

  return (
    <CContainer>
      {/* Add Statement Button */}
      <div className="d-grid gap-2 py-3">
          <CButton color='primary' onClick={handleOpenModal}>Add Statement +</CButton>
      </div> 


      {/* Add Statement Modal */}
      <AddStatementModal
        visible={isAddModalVisible}
        onClose={handleCloseModal}
        onUploadSuccess={handleUploadSuccess}
      />

      {/* Client Statements Page */}
      <ClientStatementsPage />
    </CContainer>
  );
};

export default Statements;