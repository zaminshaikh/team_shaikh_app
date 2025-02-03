import { SetStateAction, useEffect, useRef, useState } from "react";
import { CBadge, CButton, CCol, CContainer, CHeader, CHeaderBrand, CMultiSelect, CRow, CSmartTable, CSpinner, CToaster } from "@coreui/react-pro";
import { Activity, DatabaseService, Client, formatCurrency, ScheduledActivity } from "src/db/database";
import { CreateActivity } from "./CreateActivity";
import DeleteActivity from "./DeleteActivity";
import EditActivity from "./EditActivity";
import { cilArrowRight, cilReload } from "@coreui/icons";
import CIcon from "@coreui/icons-react";
import type { Option } from "@coreui/react-pro/dist/esm/components/multi-select/types";
import Activities from './Activities';

interface TableProps {
    scheduledActivities: ScheduledActivity[];
    setScheduledActivities: (activities: ScheduledActivity[]) => void;
}

const ScheduledActivitiesTable: React.FC<TableProps> = ({scheduledActivities, setScheduledActivities}) => {
    const [isLoading, setIsLoading] = useState(true);

    const [clients, setClients] = useState<Client[]>([]);
    const [selectedClient, setSelectedClient] = useState<string | number | undefined>(undefined);

    const [showDeleteActivityModal, setShowDeleteActivityModal] = useState(false);
    const [showEditActivityModal, setShowEditActivityModal] = useState(false);

    const [currentActivity, setCurrentActivity] = useState<Activity | undefined>(undefined);
    
    useEffect(() => {
        const fetchActivities = async () => {
            const db = new DatabaseService();
            const newScheduledActivities = await db.getScheduledActivities();
            const clients = await db.getClients();

            setScheduledActivities(newScheduledActivities); // Store the original activities
            setClients(clients);

            setIsLoading(false);
        };
        fetchActivities();
    }, []);

    if (isLoading) {
        return( 
            <div className="text-center">
                <CSpinner color="primary"/>
            </div>
        )
    }

    const columns = [
        {
            key: 'type',
            label: 'Type',
            sorter: false,
        },
        {
            key: 'parentName',
            label: 'Client',
        },
        {   
            label: 'Scheduled Time',
            key: 'formattedTime',
            _style: { width: '20%' },
        },
        {
            key: 'recipient',
            label: 'Recipient',
        },
        {
            key: 'amount',
            label: 'Amount',
        },
        {
            key: 'status',
            label: 'Status',
            _style: { width: '8%' },
        },
        {
            key: 'fund',
            _style: { width: '7%' },
        },
        {
            key: 'edit',
            label: '',
            _style: { width: '1%' },
            filter: false,
            sorter: false,
        },
        {
            key: 'delete',
            label: '',
            _style: { width: '1%' },
            filter: false,
            sorter: false,
        },
    ]

    const getBadge = (status: string) => {
        switch (status.toLowerCase()) {
            case 'deposit':
                return 'success'
            case 'profit':
                return 'info'
            case 'income':
                return 'info'
            case 'pending':
                return 'warning'
            case 'withdrawal':
                return 'danger'
            case 'completed':
                return 'success'
            default:
                return 'primary'
        }
      }

    function toSentenceCase(str: string) {
        return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
    }

    return (
        <CContainer>
            <h1 className="pt-5 pb-2">Scheduled Activities</h1>
            {showDeleteActivityModal && <DeleteActivity showModal={showDeleteActivityModal} setShowModal={setShowDeleteActivityModal} activity={currentActivity} isScheduled={true} selectedClient={selectedClient} setScheduledActivities={setScheduledActivities}/>}
            {showEditActivityModal && <EditActivity showModal={showEditActivityModal} setShowModal={setShowEditActivityModal} clients={clients} activity={currentActivity} isScheduled={true} selectedClient={selectedClient} setScheduledActivities={setScheduledActivities} />}
            <CSmartTable
                activePage={1}
                cleaner
                clickableRows
                columns={columns}
                columnFilter
                columnSorter
                items={scheduledActivities.map((scheduledActivity) => ({...scheduledActivity.activity, id: scheduledActivity.id, status: scheduledActivity.status}))}
                itemsPerPageSelect
                itemsPerPage={20}
                pagination
                sorterValue={{ column: 'formattedTime', state: 'desc' }}
                scopedColumns={{
                    type: (item: Activity) => (
                        <td>
                            <CBadge color={getBadge(item.type)}>{toSentenceCase(item.type)}</CBadge>
                        </td>
                    ),
                    amount: (item: Activity) => (
                        <td>
                            {formatCurrency(item.amount)}
                        </td>
                    ),
                    status: (item: any) => (
                        <td>
                            <CBadge color={getBadge(item.status)}>{toSentenceCase(item.status)}</CBadge>
                        </td>
                    ),
                    edit: (item: any) => {
                        return (
                        <td className="py-2">
                            <CButton
                            color="warning"
                            variant="outline"
                            shape="square"
                            size="sm"
                            disabled={item.status === 'completed'}
                            onClick={async () => {
                                setCurrentActivity(item);
                                setShowEditActivityModal(true);
                                setSelectedClient(item.parentDocId);
                            }}
                            >
                            Edit
                            </CButton>
                        </td>
                        )
                    },
                    delete: (item: Activity) => {
                        return (
                        <td className="py-2">
                            <CButton
                            color="danger"
                            variant="outline"
                            shape="square"
                            size="sm"
                            onClick={() => {
                                setCurrentActivity(item);
                                setShowDeleteActivityModal(true);
                                setSelectedClient(item.parentDocId);
                            }}
                            >
                            Delete
                            </CButton>
                            {/* <CToaster className="p-3" placement="top-end" push={toast} ref={toaster} /> */}
                        </td>
                        )
                    },
            }} />
        </CContainer>
    );
}

export default ScheduledActivitiesTable;