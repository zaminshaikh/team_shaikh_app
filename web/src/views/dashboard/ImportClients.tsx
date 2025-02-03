import { CButton, CFormInput, CModal, CModalBody, CModalFooter, CModalHeader, CModalTitle, CTable, CTableBody, CTableDataCell, CTableHead, CTableHeaderCell, CTableRow } from "@coreui/react-pro";
import { useEffect, useState } from "react";
import React from "react";
import { AssetDetails, Client, DatabaseService, emptyClient } from "src/db/database";
import Papa from "papaparse";
import * as XLSX from "xlsx";
import EditClient from './EditClient';
import CreateClient from "./CreateClient";
import { ValidateClient } from "./ClientInputModalBody";
import { parseDateWithTwoDigitYear } from "src/utils/utilities";

interface ShowModalProps {
    showModal: boolean;
    setShowModal: (show: boolean) => void;
    clients: Client[];
}

export const ImportClients: React.FC<ShowModalProps> = ({ showModal, setShowModal, clients }) => {
    const [file, setFile] = useState<File | null>(null);
    const [clientStates, setClientStates] = useState<Client[]>([]);
    const [editClientIndex, setEditClientIndex] = useState<number | null>(null);

    const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        if (event.target.files && event.target.files.length > 0) {
            const selectedFile = event.target.files[0];
            setFile(selectedFile);
            parseFile(selectedFile);
        }
    };

    const parseFile = (file: File) => {
        const fileExtension = file.name.split('.').pop()?.toLowerCase();
        if (fileExtension === 'csv') {
            parseCSV(file);
        } else if (fileExtension === 'xlsx') {
            parseXLSX(file);
        }
    };

    const parseCSV = (file: File) => {
        Papa.parse(file, {
            header: true,
            complete: (results) => {
                const clients = results.data.map((row: any) => createClientState(row));
                setClientStates(clients);
                console.log(clients);
            }
        });
    };

    const parseXLSX = (file: File) => {
        const reader = new FileReader();
        reader.onload = (event) => {
            const data = new Uint8Array(event.target?.result as ArrayBuffer);
            const workbook = XLSX.read(data, { type: 'array' });
            const sheetName = workbook.SheetNames[0];
            const worksheet = workbook.Sheets[sheetName];
            const json = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
            const headers = json[0] as string[];
            const rows = json.slice(1);
            const clients = rows.map((row: any) => {
                const rowData = headers.reduce((acc, header, index) => {
                    acc[header] = row[index];
                    return acc;
                }, {} as any);
                return createClientState(rowData);
            });
            setClientStates(clients);
            console.log(clients);
        };
        reader.readAsArrayBuffer(file);
    };

    const createClientState = (row: any): Client => {
        const newState: Client = {
            ...emptyClient,
            firstName: row["CLIENT'S FIRST NAME"] || '',
            lastName: row["CLIENT'S LAST NAME"] || '',
            companyName: row["COMPANY NAME"] || '',
            address: row["ADDRESS"] || '',
            dob: row["DOB"] ? new Date(row["DOB"]) : null,
            phoneNumber: row["PHONE NUMBER"] || '',
            initEmail: row["Email"] || '',
            firstDepositDate: row["FIRST DEPOSIT DATE"] ? new Date(row["FIRST DEPOSIT DATE"]) : null,
            beneficiaries: row["BENEFICIARY"] ? [row["BENEFICIARY"]] : [],
            assets: {
                agq: {
                    personal: {
                        amount: parseFloat(row["PERSONAL"]) || 0,
                        firstDepositDate: row["FIRST DEPOSIT DATE"] ? new Date(row["FIRST DEPOSIT DATE"]) : null,
                        displayTitle: 'Personal',
                        index: 0,
                    },
                    company: {
                        amount: parseFloat(row["COMPANY"]) || 0,
                        firstDepositDate: null,
                        displayTitle: row["COMPANY NAME"] || 'Company',
                        index: 1,
                    },
                    trad: {
                        amount: parseFloat(row["IRA"]) || 0,
                        firstDepositDate: null,
                        displayTitle: 'IRA',
                        index: 2,
                    },
                    roth: {
                        amount: parseFloat(row["ROTH IRA"]) || 0,
                        firstDepositDate: null,
                        displayTitle: 'Roth IRA',
                        index: 3,
                    },
                    sep: {
                        amount: parseFloat(row["SEP IRA"]) || 0,
                        firstDepositDate: null,
                        displayTitle: 'SEP IRA',
                        index: 4,
                    },
                    nuviewTrad: {
                        amount: parseFloat(row["NUVIEW CASH IRA"]) || 0,
                        firstDepositDate: null,
                        displayTitle: 'NUVIEW CASH IRA',
                        index: 5,
                    },
                    nuviewRoth: {
                        amount: parseFloat(row["NUVIEW CASH ROTH IRA"]) || 0,
                        firstDepositDate: null,
                        displayTitle: 'NUVIEW CASH ROTH IRA',
                        index: 6,
                    },
                },
                ak1: {
                    personal: {
                        amount: 0,
                        firstDepositDate: null,
                        displayTitle: 'Personal',
                        index: 0,
                    }
                },
            },
            activities: [
                {
                    amount: parseFloat(row["FIRST DEPOSIT AMOUNT"]), 
                    fund: 'AGQ', type: 'deposit', 
                    time: parseDateWithTwoDigitYear(row["FIRST DEPOSIT DATE"]) ?? new Date(),
                    recipient: row["CLIENT'S FIRST NAME"] + ' ' + row["CLIENT'S LAST NAME"],
                    formattedTime: parseDateWithTwoDigitYear(row["FIRST DEPOSIT DATE"])?.toLocaleDateString(),
                    notes: parseFloat(row["FIRST DEPOSIT AMOUNT"]) > 0 ? 'Initial Deposit' : '',
                    parentName: row["CLIENT'S FIRST NAME"] + ' ' + row["CLIENT'S LAST NAME"],
                },
            ]
        };
    
        return {
            ...newState,
            assets: {
                agq: filterAssets(newState.assets.agq),
                ak1: filterAssets(newState.assets.ak1),
            }
        };
         
    };

    const handleEditClient = (index: number) => {
        setEditClientIndex(index);
    };

    const handleSaveClient = (updatedClient: Client) => {
        
        const updatedClients = [...clientStates];
        if (editClientIndex !== null) {
            updatedClients[editClientIndex] = updatedClient;
            setClientStates(updatedClients);
            setEditClientIndex(null);
        }
    };

    const handleRemoveClient = (index: number) => {
        const updatedClients = clientStates.filter((_, i) => i !== index);
        setClientStates(updatedClients);
    };

    const handleImportClients = () => {
        console.log("CALLED")
        const db = new DatabaseService();
        const promises = clientStates.map(client => {
            return db.createClient(client)
        })
        Promise.all(promises).then(() => {
            setShowModal(false);
            window.location.reload();
        });
    }

    const handleAddClient = (index: number) => {
        const client = clientStates[index];
        const db = new DatabaseService();
        db.createClient(client)
            .then(() => {
                // Remove client from clientStates
                const updatedClients = clientStates.filter((_, i) => i !== index);
                setClientStates(updatedClients);
            })
            .catch((error) => {
                console.error("Error adding client:", error);
                // Optionally, display an error message to the user
            });
    };
    
    useEffect(() => {
        console.log(clientStates);
    }, [clientStates]);

    return (
        <div>
            <CModal
                scrollable
                alignment="center"
                visible={showModal}
                backdrop="static"
                size="xl"
                onClose={() => setShowModal(false)}
            >
                <CModalHeader>
                    <CModalTitle>Import Clients</CModalTitle>
                </CModalHeader>
                <CModalBody className="p-5">
                    <CFormInput type="file" onChange={handleFileChange} />
                    <div className="mt-3"></div>
                    <CTable striped hover >
                        <CTableHead >
                            <CTableRow>
                                <CTableHeaderCell>Index</CTableHeaderCell>
                                <CTableHeaderCell>First Name</CTableHeaderCell>
                                <CTableHeaderCell>Last Name</CTableHeaderCell>
                                <CTableHeaderCell>Actions</CTableHeaderCell>
                            </CTableRow>
                        </CTableHead>
                        <CTableBody>
                            {clientStates.map((client, index) => (
                                <CTableRow key={index}>
                                    <CTableDataCell>{index + 1}</CTableDataCell>
                                    <CTableDataCell>{client.firstName}</CTableDataCell>
                                    <CTableDataCell>{client.lastName}</CTableDataCell>
                                    <CTableDataCell>
                                        <CButton className="me-3" color="warning"  variant='outline' onClick={() => handleEditClient(index)}>Edit Client</CButton>
                                        <CButton className="me-3"color="danger"  variant='outline' onClick={() => handleRemoveClient(index)}>Remove</CButton>
                                        <CButton color="success" variant='outline' onClick={() => handleAddClient(index)}>Add</CButton>
                                    </CTableDataCell>
                                </CTableRow>
                            ))}
                        </CTableBody>
                    </CTable>
                </CModalBody>
                <CModalFooter>
                    <CButton color="secondary" variant="outline" onClick={() => setShowModal(false)}>Cancel</CButton>
                    <CButton color="primary" onClick={() => handleImportClients()}>Import All</CButton>
                </CModalFooter>
            </CModal>

            {editClientIndex !== null && (
                <EditClient
                    showModal={editClientIndex !== null}
                    setShowModal={() => setEditClientIndex(null)}
                    clients={clients}
                    setClients={() => {}}
                    activeClient={clientStates[editClientIndex]}
                    onSubmit={handleSaveClient}
                    reload={false}
                />
            )}
        </div>
    );
};

export default ImportClients;

function filterAssets(assets: { [assetType: string]: AssetDetails; }): { [assetType: string]: AssetDetails; } {
    return Object.fromEntries(
        Object.entries(assets).filter(([key, value]) => value.amount !== 0)
    );
}