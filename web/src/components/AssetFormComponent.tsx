// src/components/AssetFormComponent.tsx

import React, { useState } from "react";
import {
  CInputGroup,
  CInputGroupText,
  CFormInput,
  CButton,
  CModal,
  CModalHeader,
  CModalBody,
  CModalFooter,
  CTooltip,
} from "@coreui/react-pro";
import CIcon from "@coreui/icons-react";
import { cilPencil, cilTrash, cilArrowTop, cilArrowBottom } from "@coreui/icons";
import { Client } from "../db/database";

interface AssetFormComponentProps {
  title: string;
  id: string;
  fundKey: string;
  assetType: string;
  disabled?: boolean;
  clientState: Client;
  setClientState: (clientState: Client) => void;
  incrementAmount: number;
  onRemove: (fundKey: string, assetType: string) => void;
  onEdit: (fundKey: string, oldAssetType: string, newAssetTitle: string) => void;
  isEditable: boolean; // Indicates if the asset can be edited or deleted
  onMoveUp: (fundKey: string, assetType: string) => void; // Function to move the asset up
  onMoveDown: (fundKey: string, assetType: string) => void; // Function to move the asset down
  isFirst: boolean; // Indicates if the asset is the first in the list
  isLast: boolean; // Indicates if the asset is the last in the list
}

export const AssetFormComponent: React.FC<AssetFormComponentProps> = ({
  title,
  id,
  fundKey,
  assetType,
  disabled = false,
  clientState,
  setClientState,
  incrementAmount,
  onRemove,
  onEdit,
  isEditable,
  onMoveUp,
  onMoveDown,
  isFirst,
  isLast,
}) => {
  const asset = clientState.assets[fundKey]?.[assetType] ?? {
    amount: 0,
    firstDepositDate: null,
    displayTitle: title,
    index: 0,
  };

  // State for managing Edit Asset modal
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editedTitle, setEditedTitle] = useState<string>(title);

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (/^\d*\.?\d{0,2}$/.test(value)) {
      const parsedValue = parseFloat(value);

      // Update clientState
      const newState: Client = {
        ...clientState,
        assets: {
          ...clientState.assets,
          [fundKey]: {
            ...clientState.assets[fundKey],
            [assetType]: {
              ...asset,
              amount: parsedValue,
            },
          },
        },
      };
      setClientState(newState);
    }
  };

  const handleAmountBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (value === "" || isNaN(parseFloat(value))) {
      // Update clientState
      const newState: Client = {
        ...clientState,
        assets: {
          ...clientState.assets,
          [fundKey]: {
            ...clientState.assets[fundKey],
            [assetType]: {
              ...asset,
              amount: 0,
            },
          },
        },
      };
      setClientState(newState);
    }
  };

  // Handle firstDepositDate change
  const handleFirstDepositDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const dateValue = e.target.value ? new Date(e.target.value) : null;

    // Update clientState
    const newState: Client = {
      ...clientState,
      assets: {
        ...clientState.assets,
        [fundKey]: {
          ...clientState.assets[fundKey],
          [assetType]: {
            ...asset,
            firstDepositDate: dateValue,
          },
        },
      },
    };
    setClientState(newState);
  };

  // Function to handle opening the Edit Asset modal
  const openEditModal = () => {
    setEditedTitle(title);
    setIsEditModalOpen(true);
  };

  // Function to handle closing the Edit Asset modal
  const closeEditModal = () => {
    setIsEditModalOpen(false);
    setEditedTitle(title);
  };

  // Function to handle saving the edited asset title
  const handleSaveEdit = () => {
    const trimmedTitle = editedTitle.trim();
    if (trimmedTitle === "") {
      alert("Asset name cannot be empty.");
      return;
    }

    // Pass the edit to the parent component
    onEdit(fundKey, assetType, trimmedTitle);

    // Close the modal
    setIsEditModalOpen(false);
  };

  // Function to handle removing the asset
  const handleRemoveAsset = () => {
    onRemove(fundKey, assetType);
  };

  return (
    <>
      {/* Asset Amount and Actions */}
      <CInputGroup className="mb-3 pb-3">
        <CInputGroupText style={{ width: "200px" }}>{asset.displayTitle}</CInputGroupText>
        <CInputGroupText>$</CInputGroupText>
        <CFormInput
          id={id}
          disabled={disabled}
          type="number"
          step={incrementAmount}
          value={asset.amount}
          onChange={handleAmountChange}
          onBlur={handleAmountBlur}
        />
        <CInputGroupText style={{ width: "200px" }}>First Deposit Date</CInputGroupText>
        <CFormInput
          type="date"
          disabled={disabled}
          value={asset.firstDepositDate ? asset.firstDepositDate.toISOString().substring(0, 10) : ""}
          onChange={handleFirstDepositDateChange}
        />
        {/* Conditionally render Edit, Remove, Move Up, and Move Down buttons based on isEditable */}
        {isEditable && (
          <>
            <CTooltip content={`Edit Asset Name`} placement="top">
              <CButton
                variant="outline"
                className="ms-2 p-0 border-0"
                onClick={openEditModal}
                aria-label={`Edit ${title}`}
                disabled={disabled}
              >
                <CIcon icon={cilPencil} size="lg" />
              </CButton>
            </CTooltip>
            <CTooltip content={`Remove ${title} as an Asset`} placement="top">
              <CButton
                variant="ghost"
                className="ms-2 p-0 border-0"
                onClick={handleRemoveAsset}
                aria-label={`Remove ${title}`}
                disabled={disabled}
              >
                <CIcon icon={cilTrash} size="lg" />
              </CButton>
            </CTooltip>
            {/* Move Up Button */}
            <CTooltip content="Move Up" placement="top">
              <CButton
                variant="outline"
                className="ms-2 p-0 border-0"
                onClick={() => onMoveUp(fundKey, assetType)}
                aria-label={`Move ${title} Up`}
                disabled={disabled || isFirst}
              >
                <CIcon icon={cilArrowTop} size="lg" />
              </CButton>
            </CTooltip>
            {/* Move Down Button */}
            <CTooltip content="Move Down" placement="top">
              <CButton
                variant="outline"
                className="ms-2 p-0 border-0"
                onClick={() => onMoveDown(fundKey, assetType)}
                aria-label={`Move ${title} Down`}
                disabled={disabled || isLast}
              >
                <CIcon icon={cilArrowBottom} size="lg" />
              </CButton>
            </CTooltip>
          </>
        )}
      </CInputGroup>

      {/* Edit Asset Modal */}
      {isEditable && (
        <CModal visible={isEditModalOpen} onClose={closeEditModal} alignment="center" backdrop="static">
          <CModalHeader>Edit Asset</CModalHeader>
          <CModalBody>
            <CFormInput
              label="Asset Name"
              placeholder="Enter new asset name"
              value={editedTitle}
              onChange={(e) => setEditedTitle(e.target.value)}
              disabled={disabled}
            />
          </CModalBody>
          <CModalFooter>
            <CButton color="secondary" onClick={closeEditModal} disabled={disabled}>
              Cancel
            </CButton>
            <CButton color="primary" onClick={handleSaveEdit} disabled={disabled}>
              Save
            </CButton>
          </CModalFooter>
        </CModal>
      )}
    </>
  );
};