// src/components/EditAssetsSection.tsx

import React, { useEffect, useState } from "react";
import {
  CContainer,
  CButton,
  CModal,
  CModalHeader,
  CModalBody,
  CModalFooter,
  CFormInput,
} from "@coreui/react-pro";
import { Client } from "../db/database";
import { AssetFormComponent } from "./AssetFormComponent";
import { cilArrowTop, cilArrowBottom } from "@coreui/icons"; // Import icons for reordering

interface EditAssetsSectionProps {
  clientState: Client;
  setClientState: (clientState: Client) => void;
  activeFund?: string;
  incrementAmount?: number;
  viewOnly?: boolean;
}

// Define keys to exclude (case-insensitive)
const excludedAssetKeys = ["total", "fund"];

export const EditAssetsSection: React.FC<EditAssetsSectionProps> = ({
  clientState,
  setClientState,
  activeFund,
  incrementAmount = 10000,
  viewOnly = false,
}) => {
  // State for managing the "Add Asset" modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [currentFundKey, setCurrentFundKey] = useState<string | null>(null);
  const [newAssetTitle, setNewAssetTitle] = useState<string>("");

  // Function to handle opening the modal
  const openAddAssetModal = (fundKey: string) => {
    setCurrentFundKey(fundKey);
    setNewAssetTitle("");
    setIsModalOpen(true);
  };

  // Function to handle closing the modal
  const closeAddAssetModal = () => {
    setIsModalOpen(false);
    setCurrentFundKey(null);
    setNewAssetTitle("");
  };

  // Function to handle adding a new asset
  const handleAddAsset = () => {
    if (!currentFundKey) return;

    const assetTitleTrimmed = newAssetTitle.trim();
    if (assetTitleTrimmed === "") {
      alert("Asset name cannot be empty.");
      return;
    }

    // Prevent adding 'total', 'Total', 'fund', 'Fund'
    if (excludedAssetKeys.includes(assetTitleTrimmed.toLowerCase())) {
      alert("The asset name 'total' or 'fund' is reserved and cannot be used.");
      return;
    }

    // Generate a unique type for the new asset
    const sanitizedTitle = assetTitleTrimmed.toLowerCase().replace(/\s+/g, "-");
    const newAssetType = sanitizedTitle; // Use this as the dynamic key

    // Check for duplicates
    const fundAssets = clientState.assets[currentFundKey] || {};
    const duplicateTitle = Object.values(fundAssets).some(
      (asset) => asset.displayTitle.toLowerCase() === assetTitleTrimmed.toLowerCase()
    );
    if (duplicateTitle) {
      alert("An asset with this name already exists.");
      return;
    }

    // Determine the next index by finding the maximum existing index and adding 1
    const maxIndex = Math.max(
      -1,
      ...Object.values(fundAssets)
        .filter((asset) => !excludedAssetKeys.includes(asset.displayTitle.toLowerCase()))
        .map((asset) => asset.index ?? 0)
    );

    // Initialize the new asset in clientState.assets using the correct dynamic key
    const newState: Client = {
      ...clientState,
      assets: {
        ...clientState.assets,
        [currentFundKey]: {
          ...fundAssets,
          [newAssetType]: {
            amount: 0,
            firstDepositDate: null,
            displayTitle: assetTitleTrimmed,
            index: maxIndex + 1, // Assign the next index
          },
        },
      },
    };
    setClientState(newState);

    // Close the modal
    closeAddAssetModal();
  };

  // Function to handle removing an asset
  const handleRemoveAsset = (fundKey: string, assetType: string) => {
    // Prevent removing protected assets and excluded keys
    if (excludedAssetKeys.includes(assetType.toLowerCase())) {
      alert("This asset cannot be removed.");
      return;
    }

    if (!window.confirm(`Are you sure you want to remove the asset "${assetType}"?`)) {
      return;
    }

    // Remove from clientState.assets
    const fundAssets = { ...clientState.assets[fundKey] };
    delete fundAssets[assetType];

    // After deletion, reassign indices to maintain order consistency
    const updatedAssetsArray = Object.entries(fundAssets)
      .filter(([type]) => !excludedAssetKeys.includes(type.toLowerCase()))
      .sort(([, a], [, b]) => (a.index ?? 0) - (b.index ?? 0))
      .map(([type, asset], idx) => {
        asset.index = idx;
        return [type, asset];
      });

    const updatedAssets = Object.fromEntries(updatedAssetsArray);

    const newState: Client = {
      ...clientState,
      assets: {
        ...clientState.assets,
        [fundKey]: updatedAssets,
      },
    };
    setClientState(newState);
  };

  // Function to handle editing an asset title
  const handleEditAsset = (fundKey: string, oldAssetType: string, newAssetTitle: string) => {
    const assetTitleTrimmed = newAssetTitle.trim();
    if (assetTitleTrimmed === "") {
      alert("Asset name cannot be empty.");
      return;
    }

    // Prevent renaming to 'total', 'Total', 'fund', 'Fund'
    if (excludedAssetKeys.includes(assetTitleTrimmed.toLowerCase())) {
      alert("The asset name 'total' or 'fund' is reserved and cannot be used.");
      return;
    }

    // Generate a new type based on the edited title
    const newAssetType = assetTitleTrimmed.toLowerCase().replace(/\s+/g, "-");

    // Check for duplicate asset titles within the same fund
    const fundAssets = clientState.assets[fundKey];
    const duplicateTitle = Object.values(fundAssets).some(
      (asset) =>
        asset.displayTitle.toLowerCase() === assetTitleTrimmed.toLowerCase() &&
        asset.displayTitle.toLowerCase() !== fundAssets[oldAssetType].displayTitle.toLowerCase()
    );
    if (duplicateTitle) {
      alert("An asset with this name already exists.");
      return;
    }

    // Update clientState.assets
    const oldAsset = fundAssets[oldAssetType];
    const newAssets = {
      ...fundAssets,
      [newAssetType]: {
        ...oldAsset,
        displayTitle: assetTitleTrimmed,
      },
    };
    delete newAssets[oldAssetType];

    const newState: Client = {
      ...clientState,
      assets: {
        ...clientState.assets,
        [fundKey]: newAssets,
      },
    };
    setClientState(newState);
  };

  // Function to move an asset up in the order
  const handleMoveAssetUp = (fundKey: string, assetType: string) => {
    const fundAssets = { ...clientState.assets[fundKey] };
    const assetsArray = Object.entries(fundAssets)
      .filter(([type]) => !excludedAssetKeys.includes(type.toLowerCase()))
      .sort(([, a], [, b]) => (a.index ?? 0) - (b.index ?? 0));

    const index = assetsArray.findIndex(([type]) => type === assetType);

    if (index > 0) {
      const prevAssetType = assetsArray[index - 1][0];
      const currentAsset = fundAssets[assetType];
      const prevAsset = fundAssets[prevAssetType];

      // Swap indices
      const tempIndex = currentAsset.index;
      currentAsset.index = prevAsset.index;
      prevAsset.index = tempIndex;

      const newState: Client = {
        ...clientState,
        assets: {
          ...clientState.assets,
          [fundKey]: {
            ...fundAssets,
            [assetType]: currentAsset,
            [prevAssetType]: prevAsset,
          },
        },
      };
      setClientState(newState);
    }
  };

  // Function to move an asset down in the order
  const handleMoveAssetDown = (fundKey: string, assetType: string) => {
    const fundAssets = { ...clientState.assets[fundKey] };
    const assetsArray = Object.entries(fundAssets)
      .filter(([type]) => !excludedAssetKeys.includes(type.toLowerCase()))
      .sort(([, a], [, b]) => (a.index ?? 0) - (b.index ?? 0));

    const index = assetsArray.findIndex(([type]) => type === assetType);

    if (index < assetsArray.length - 1) {
      const nextAssetType = assetsArray[index + 1][0];
      const currentAsset = fundAssets[assetType];
      const nextAsset = fundAssets[nextAssetType];

      // Swap indices
      const tempIndex = currentAsset.index;
      currentAsset.index = nextAsset.index;
      nextAsset.index = tempIndex;

      const newState: Client = {
        ...clientState,
        assets: {
          ...clientState.assets,
          [fundKey]: {
            ...fundAssets,
            [assetType]: currentAsset,
            [nextAssetType]: nextAsset,
          },
        },
      };
      setClientState(newState);
    }
  };

  return (
    <CContainer className="py-3">
      {Object.entries(clientState.assets).map(([fundKey, fundAssets]) => {
        // Sort assets based on the index property
        const sortedAssets = Object.entries(fundAssets)
          .filter(([assetType]) => !excludedAssetKeys.includes(assetType.toLowerCase()))
          .sort(([, a], [, b]) => (a.index ?? 0) - (b.index ?? 0));

        return (
          <div key={fundKey} className="mb-5">
            <div className="mb-2 pb-3">
              <h5>{fundKey.toUpperCase()} Fund Assets</h5>
            </div>
            {sortedAssets.map(([assetType, asset], index) => {
              // Determine if the asset is the first or last in the list
              const isFirst = index === 0;
              const isLast = index === sortedAssets.length - 1;

              // Determine the disabled state based on props and asset type
              let isDisabled = viewOnly;

              if (!isDisabled) {
                if (activeFund !== undefined) {
                  if (fundKey.toUpperCase() !== activeFund.toUpperCase()) {
                    isDisabled = true;
                  }
                }
              }

              return (
                <AssetFormComponent
                  key={`${fundKey}-${assetType}`}
                  title={asset.displayTitle}
                  id={`${fundKey}-${assetType}`}
                  fundKey={fundKey}
                  assetType={assetType}
                  clientState={clientState}
                  setClientState={setClientState}
                  disabled={isDisabled}
                  incrementAmount={incrementAmount}
                  onRemove={handleRemoveAsset}
                  onEdit={handleEditAsset}
                  onMoveUp={handleMoveAssetUp}
                  onMoveDown={handleMoveAssetDown}
                  isEditable={!isDisabled} // All assets are editable unless restricted
                  isFirst={isFirst}
                  isLast={isLast}
                />
              );
            })}
            {/* Add Asset Button at the Bottom */}
            {!viewOnly && (
              <div className="mt-3">
                <CButton color="primary" onClick={() => openAddAssetModal(fundKey)}>
                  Add Asset
                </CButton>
              </div>
            )}
          </div>
        );
      })}

      {/* Add Asset Modal */}
      <CModal visible={isModalOpen} onClose={closeAddAssetModal} alignment="center">
        <CModalHeader>Add New Asset</CModalHeader>
        <CModalBody>
          <CFormInput
            label="Asset Name"
            placeholder="Enter asset name (e.g., Personal 2, IRA 3, Custom Field)"
            value={newAssetTitle}
            onChange={(e) => setNewAssetTitle(e.target.value.replace(/["']/g, ""))}
          />
        </CModalBody>
        <CModalFooter>
          <CButton color="secondary" onClick={closeAddAssetModal}>
            Cancel
          </CButton>
          <CButton color="primary" onClick={handleAddAsset}>
            Add
          </CButton>
        </CModalFooter>
      </CModal>
    </CContainer>
  );
};