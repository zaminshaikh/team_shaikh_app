import React, { useState } from 'react'
import { CButton, CModal, CModalHeader, CModalTitle, CModalBody, CModalFooter, CSmartTable, CBadge, CFormInput, CInputGroup, CInputGroupText, CLoadingButton } from '@coreui/react-pro'
import { toSentenceCase } from "src/utils/utilities";
import { Activity, DatabaseService, formatCurrency } from 'src/db/database'
import { faExclamationTriangle, faLock } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { signInWithEmailAndPassword, getAuth } from 'firebase/auth'
import CIcon from '@coreui/icons-react'
import { cilLockLocked } from '@coreui/icons'
import { set } from 'date-fns';

interface DeleteSelectedActivitiesProps {
  showModal: boolean;
  setShowModal: (show: boolean) => void;
  selectedActivities: Activity[];
  setSelectedActivities: (activities: Activity[]) => void;
  allActivities: Activity[];
  setAllActivities: (activities: Activity[]) => void;
  filteredActivities: Activity[];
  setFilteredActivities: (activities: Activity[]) => void;
  selectedClient?: string | number;
}

export const DeleteSelectedActivities: React.FC<DeleteSelectedActivitiesProps> = ({
  showModal,
  setShowModal,
  selectedActivities,
  setSelectedActivities,
  allActivities,
  setAllActivities,
  filteredActivities,
  setFilteredActivities,
  selectedClient,
}) => {
  const [password, setPassword] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const auth = getAuth()
  const db = new DatabaseService()
  const [isLoading, setIsLoading] = useState(false)

  const columns = [
    { key: 'type', label: 'Type' },
    {
        key: 'parentName',
        label: 'Client',
    },
    { key: 'amount', label: 'Amount' },
    { key: 'recipient', label: 'Recipient' },
    { key: 'formattedTime', label: 'Time' },
  ]

  const getBadge = (status: string) => {
    switch (status.toLowerCase()) {
      case 'deposit':
        return 'success'
      case 'profit':
      case 'income':
        return 'info'
      case 'pending':
        return 'warning'
      case 'withdrawal':
        return 'danger'
      default:
        return 'primary'
    }
  }

  const handleDelete = async () => {
    try {
      setIsLoading(true)
      // Verify password by attempting to sign in
      if (!auth.currentUser?.email) {
        setPasswordError('No authenticated user found')
        return
      }

      await signInWithEmailAndPassword(auth, auth.currentUser.email, password)
      
      // If sign in successful, proceed with deletion
      for (const activity of selectedActivities) {
        await db.deleteActivity(activity)
        await db.deleteNotification(activity)
      }
      setSelectedActivities([]);
      setIsLoading(false)
      setShowModal(false)

      setAllActivities(allActivities.filter(a => !selectedActivities.find(sa => sa.id === a.id)))
      setFilteredActivities(filteredActivities.filter(a => !selectedActivities.find(sa => sa.id === a.id)))
    } catch (error) {
      setPasswordError('Incorrect password')
      console.error('Failed to delete selected activities:', error)
    }
  }

  return (
    <CModal visible={showModal} onClose={() => setShowModal(false)} size="xl" alignment='center' scrollable>
      <CModalHeader>
        <FontAwesomeIcon className="me-3" icon={faExclamationTriangle} color="red" size='xl'/>
        <CModalTitle style={{fontSize: '2rem'}}>Delete Selected Activities?</CModalTitle></CModalHeader>
      <CModalBody>
        <div className="mb-3">
          <strong>Are you sure you want to delete the following activities?</strong>
        </div>
        <CSmartTable
          items={selectedActivities}
          columns={columns}
          columnSorter
          pagination
          itemsPerPage={10}
          scopedColumns={{
            type: (item: Activity) => (
              <td>
                <CBadge color={getBadge(item.type)}>{toSentenceCase(item.type)}</CBadge>
              </td>
            ),
            amount: (item: Activity) => (
              <td>{formatCurrency(item.amount)}</td>
            ),
          }}
        />
        <div className="mt-4">
          <strong className="d-block mb-3">Please enter your password to confirm deletion:</strong>
          <CInputGroup className="mb-3">
            <CInputGroupText>
              <CIcon icon={cilLockLocked} />
            </CInputGroupText>
            <CFormInput
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value)
                setPasswordError('')
              }}
              invalid={!!passwordError}
              autoComplete="off"
            />
          </CInputGroup>
          {passwordError && (
            <div className="text-danger mb-3">{passwordError}</div>
          )}
        </div>
        <strong className="d-block mt-3 text-danger">THIS ACTION IS IRREVERSIBLE.</strong>
      </CModalBody>
      <CModalFooter>
        <CButton color="secondary" onClick={() => setShowModal(false)}>
          Cancel
        </CButton>
        <CLoadingButton 
          color="danger" 
          variant="outline" 
          onClick={handleDelete}
          disabled={!password}
          loading={isLoading}
        >
          Confirm Delete
        </CLoadingButton>
      </CModalFooter>
    </CModal>
  )
}

export default DeleteSelectedActivities