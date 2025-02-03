import { CModalBody, CInputGroup, CInputGroupText, CFormInput, CFormCheck, CMultiSelect, CContainer, CRow, CCol, CButton, CLoadingButton, CTable, CTableHead, CTableHeaderCell, CTableRow, CTableBody, CTableDataCell, CForm, CFormSelect, CFormTextarea } from '@coreui/react-pro';
import { Activity, DatabaseService, GraphPoint, Client, formatCurrency, emptyActivity } from '../../db/database.ts'
import { Option, OptionsGroup } from '@coreui/react-pro/dist/esm/components/multi-select/types';
import Papa from 'papaparse';
import { EditAssetsSection } from "../../components/EditAssetsSection";
import { isValid, parse, set } from 'date-fns';
import { useState, useEffect } from 'react';
import { formatDate, parseDateWithTwoDigitYear, toTitleCase } from 'src/utils/utilities.ts';
import countries from '../../utils/countries.json';
import states from '../../utils/states.json';
import provinces from '../../utils/provinces.json';

interface ClientInputProps {
    clientState: Client,
    setClientState: (clientState: Client) => void,
    clientOptions: (Option | OptionsGroup)[],
    clients?: Client[],
    setClientOptions: (options: (Option | OptionsGroup)[]) => void,
    viewOnly: boolean,
}

// Handles the file input from the client
const handleActivitiesFileChange = (event: React.ChangeEvent<HTMLInputElement>, clientState: Client, setClientState: (state: Client) => void) => {

    const getActivityType = (type: string | undefined, amount: number) => {
        if (!type) return "none";
        switch (type) {
            case "withdrawal":
                if (amount > 15000) return "withdrawal";
                else return "profit";
            case "deposit":
                if (amount > 15000) return "deposit";
                else return "profit";
            default:
                return "profit";
        }
    }

    const file = event.target.files?.[0];
    if (!file) return;

// List of exceptions to preserve original casing
const exceptions = ["LLC", "Inc", "Ltd"];

// Parse the CSV file
    Papa.parse(file, {
        header: true,
        complete: (results) => {
            // Initialize an array to store the activities
            let activities: Activity[] = [];

            results.data.forEach((row: any) => {
                // Skip if row is empty
                if (Object.values(row).every(x => (x === null || x === ''))) return;
    
                // Remove the fund type after the dash and convert the name to title case
                
                let [recipientName, fundInfo] = row["Security Name"].split('-').map((s: string) => s.trim());
                let name = toTitleCase(recipientName.trimEnd(), exceptions);
    
                // Check if name does not match client's full name or company name
                const clientFullName = clientState.firstName.trimEnd() + ' ' + clientState.lastName.trimEnd();

                // Extract and sort displayTitles by length in descending order
                const assetDisplayTitles = Object.values(clientState.assets)
                    .flatMap(fundAssets => Object.values(fundAssets))
                    .map(assetDetails => ({
                        original: assetDetails.displayTitle,
                        lower: assetDetails.displayTitle.toLowerCase(),
                    }))
                    .sort((a, b) => b.lower.length - a.lower.length); // Sort descending by length

                // Now check if any of the asset display titles are included in securityNameLower
                const securityNameLower = row["Security Name"].toLowerCase();
                let foundAsset = assetDisplayTitles.find(asset => securityNameLower.includes(asset.lower));

                if (!name.toLowerCase().includes(clientFullName.toLowerCase()) 
                    && (clientState.companyName === '' || !name.toLowerCase().includes(clientState.companyName.toLowerCase())) 
                    && !foundAsset) {
                    return;
                }
                else if (clientState.companyName != '' && name.toLowerCase().includes(clientState.companyName.toLowerCase())) { name = clientState.companyName } 
                else if (name.toLowerCase().includes(clientFullName.toLowerCase())) {
                    name = clientFullName;
                }
    
                // Determine the fund type
                let fund = fundInfo.split(' ')[0];
    
                // Parse the date string correctly
                const dateString = row["Date"] ?? row["date"];
                if (!dateString) {
                    console.warn("Date field is missing or undefined in row:", row);
                    return;
                }
    
                // Parse the date string correctly
                const parsedDate = parseDateWithTwoDigitYear(dateString);
                if (parsedDate === null) return;

                // Check for specific keywords in the Security Name and set the recipient accordingly
                let recipient = '';

                if (foundAsset) {
                    recipient = foundAsset.original;
                } else if (securityNameLower.includes(' roth ')) {
                    recipient = 'ROTH IRA';
                } else if (securityNameLower.includes(' sep ')) {
                    recipient = 'SEP IRA';
                } else if (securityNameLower.includes(' ira ')) {
                    recipient = 'IRA';
                } else {
                    recipient = name; // Default to the parsed name if no specific keyword is found
                }

                if (securityNameLower.includes('agq')) {
                    fund = 'AGQ';
                } else if (securityNameLower.includes('ak1')) {
                    fund = 'AK1';
                }
    
                // Create an activity from each row of the CSV
                const activity: Activity = {
                    fund: fund,
                    amount: Math.abs(parseFloat(row["Amount (Unscaled)"])),
                    recipient: recipient,
                    time: parsedDate,
                    formattedTime: formatDate(parsedDate),
                    type: getActivityType(row["Type"], Math.abs(parseFloat(row["Amount (Unscaled)"]))),
                    notes: undefined,
                    parentName: clientState.firstName + ' ' + clientState.lastName
                };
    
                // Add the activity to the activities array
                activities.push(activity);
            });

            console.log(activities);

            const newClientState = {
                ...clientState,
                activities: [
                    ...(clientState.activities || []),
                    ...activities
                ].sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime()),
            };

            setClientState(newClientState)
        },
    });
};


// const handleGraphPointsFileChange = (event: React.ChangeEvent<HTMLInputElement>, clientState: Client, setClientState: (state: Client) => void) => {
//     const file = event.target.files?.[0];
//     if (!file) return;

//     // Parse the CSV file
//     Papa.parse(file, {
//         header: true,
//         complete: (results) => {
//             // Initialize an array to store the activities
//             let graphPoints: GraphPoint[] = [];
    
//             results.data.forEach((row: any) => {
//                 // Skip if row is empty
//                 if (Object.values(row).every(x => (x === null || x === ''))) return;
    
//                 // Get the date string from the row
//                 const amountString = row["Amount"] ?? row["amount"];
//                 const dateString = row["Date"] ?? row["date"];
//                 if (!dateString) {
//                     console.warn("Date field is missing or undefined in row:", row);
//                     return;
//                 }
    
//                 console.log(`Raw date string: ${dateString}`);
    
//                 // Parse the date string correctly
//                 const parsedDate = parseDateWithTwoDigitYear(dateString);

//                 // Remove commas and dollar signs from the amount string and parse it as a float
//                 const cleanedAmountString = amountString.replace(/[$,]/g, '');
//                 const amount = parseFloat(cleanedAmountString);
    
//                 if (!isValid(parsedDate)) {
//                     console.warn("Invalid date format in row:", row);
//                     return;
//                 }
    
//                 console.log(`Parsed date: ${parsedDate}`);
    
//                 // Create an activity from each row of the CSV
//                 const point: GraphPoint = {
//                     time: parsedDate,
//                     amount: amount,
//                 };
    
//                 // Add the activity to the activities array
//                 graphPoints.push(point);
//             });
    
//             console.log(graphPoints);
    
//             // Update the client state with the new activities
//             const newClientState = {
//                 ...clientState,
//                 graphPoints,
//             };
//             setClientState(newClientState);
//         }
//     });
// }

/**
 * Component representing the body of the client input modal.
 * 
 * @component
 * @param {ClientInputProps} props - The properties passed to the component.
 * @param {ClientState} props.clientState - The current state of the client.
 * @param {React.Dispatch<React.SetStateAction<ClientState>>} props.setClientState - Function to update the client state.
 * @param {Array<Option>} props.clientOptions - Options for connected clients.
 * @param {boolean} props.viewOnly - Flag indicating whether the form is in view-only mode.
 * 
 * @returns {JSX.Element} The rendered component.
 */
export const ClientInputModalBody: React.FC<ClientInputProps> = ({
    clientState, 
    setClientState,
    clients,
    clientOptions,
    setClientOptions,
    viewOnly,
}) => {
    const db = new DatabaseService();
    const [ytdLoading, setYTDLoading] = useState(false);
    const [totalYTDLoading, setTotalYTDLoading] = useState(false);

    const [editActivityIndex, setEditActivityIndex] = useState<number | null>(null);
    const [editedActivity, setEditedActivity] = useState<Activity>(emptyActivity);

    useEffect(() => {
        let updatedState = { ...clientState };
    
        if (!clientState.country) {
            updatedState.country = 'US';
        } else if (clientState.country === 'CA') {
            updatedState.state = '';
        } else if (clientState.country === 'US') {
            updatedState.province = '';
        } else {
            updatedState.state = '';
            updatedState.province = '';
        }

        if (clientState.street && clientState.city && clientState.zip && clientState.country) {
            let stateOrProvince = clientState.country === 'US' ? clientState.state : clientState.province;
            if (stateOrProvince !== '') {stateOrProvince = stateOrProvince + ', ';}
            // Construct the address
            updatedState.address = `${updatedState.street}, ${updatedState.city}, ${stateOrProvince}${updatedState.zip}, ${updatedState.country}`;

        } else {
            updatedState.address = '';
        }
    
        setClientState(updatedState);
        console.log(updatedState.address);
        console.log(updatedState.state);
    }, [
        clientState.street,
        clientState.city,
        clientState.state,
        clientState.province,
        clientState.zip,
        clientState.country,
        setClientState,
    ]);

    const handleRemoveActivity = (index: number) => {
        const updatedActivities = clientState.activities?.filter((_, i) => i !== index);
        const newState = {
            ...clientState,
            activities: updatedActivities
        }
        setClientState(newState);
    };

    function maskPhoneNumber(value: string) {
        const digits = value.replace(/\D/g, '');
        let result = '';
        if (digits.length > 0) result = '(' + digits.slice(0, 3);
        if (digits.length >= 4) result += ') ' + digits.slice(3, 6);
        if (digits.length >= 7) result += '-' + digits.slice(6, 10);
        return result;
    }

    return (
            <CModalBody className="px-5">
            <CInputGroup className="mb-3 py-3">
                <CInputGroupText>Client's First Name</CInputGroupText>
                <CFormInput
                id="first-name"
                value={clientState.firstName}
                disabled={viewOnly}
                onChange={(e) => {
                    const newClientState = {
                    ...clientState,
                    firstName: e.target.value,
                    };
                    setClientState(newClientState);
                }}
                />
                <CInputGroupText>Client's Last Name</CInputGroupText>
                <CFormInput
                id="last-name"
                value={clientState.lastName}
                disabled={viewOnly}
                onChange={(e) => {
                    const newClientState = {
                    ...clientState,
                    lastName: e.target.value,
                    };
                    setClientState(newClientState);
                }}
                />
            </CInputGroup>


            <CInputGroup className="mb-3  py-3">
                <CInputGroupText>Email</CInputGroupText>
                <CFormInput type="email" id="email" value={clientState.initEmail} disabled={viewOnly}
                onChange={(e) => {
                    const newClientState = {
                    ...clientState,
                    initEmail: e.target.value,
                    };
                    setClientState(newClientState)
                }}/>
                <CInputGroupText>Phone Number</CInputGroupText>
                <CFormInput
                    id="phone-number"
                    value={clientState.phoneNumber}
                    disabled={viewOnly}
                    onChange={(e) => {
                        const newClientState = {
                        ...clientState,
                        phoneNumber: maskPhoneNumber(e.target.value),
                        };
                        setClientState(newClientState);
                    }}
                />
            </CInputGroup>


            <CInputGroup className="mb-3  py-3">
                <CInputGroupText>DOB</CInputGroupText>
                <CFormInput type="date" id="dob"  value = {clientState.dob ? clientState.dob.toISOString().split('T')[0] : ''} disabled={viewOnly}
                onChange={(e) => {
                    const inputValue = e.target.value;
                    let newDob = inputValue ? parse(inputValue, 'yyyy-MM-dd', new Date()) : null;
                    if (!newDob || !isValid(newDob)) newDob = null;
                    setClientState({ ...clientState, dob: newDob });
                }}/>
                <CInputGroupText>First Deposit Date</CInputGroupText>
                <CFormInput type="date" id="first-deposit-date" value={clientState.firstDepositDate ? clientState.firstDepositDate.toISOString().split('T')[0] : ''} disabled={viewOnly}
                onChange={(e) => {
                    const inputValue = e.target.value;
                    let newDate = inputValue ? parse(inputValue, 'yyyy-MM-dd', new Date()) : null;
                    if (!newDate || !isValid(newDate)) newDate = null;
                    setClientState({ ...clientState, firstDepositDate: newDate });
                }}/>
            </CInputGroup>

            <CInputGroup className="mb-3  py-3">
                <CInputGroupText>Address:</CInputGroupText>
                <CInputGroupText>Street</CInputGroupText>
                <CFormInput
                    id="street"
                    value={clientState.street}
                    disabled={viewOnly}
                    onChange={(e) => {
                        const newClientState = {
                            ...clientState,
                            street: e.target.value,
                        };
                        setClientState(newClientState);
                    }}
                />
                <CInputGroupText>City</CInputGroupText>
                <CFormInput
                    id="city"
                    value={clientState.city}
                    disabled={viewOnly}
                    onChange={(e) => {
                        const newClientState = {
                            ...clientState,
                            city: e.target.value,
                        };
                        setClientState(newClientState);
                    }}
                />
            </CInputGroup>

            <CInputGroup className="mb-3  py-3">
                

            {clientState.country === 'US' && (
                <>
                    <CInputGroupText>State</CInputGroupText>
                    <CFormSelect
                        id="state"
                        value={clientState.state}
                        disabled={viewOnly}
                        options={states.map(state => ({ label: state.name, value: state.code }))}
                        onChange={(e) => {
                            const newClientState = {
                                ...clientState,
                                state: e.target.value,
                            };
                            setClientState(newClientState);
                        }}
                    />
                </>
            )}

            {clientState.country === 'CA' && (
                <>
                    <CInputGroupText>Province</CInputGroupText>
                    <CFormSelect
                        id="province"
                        value={clientState.province}
                        disabled={viewOnly}
                        options={provinces.map(province => ({ label: province.name, value: province.code }))}
                        onChange={(e) => {
                            const newClientState = {
                                ...clientState,
                                province: e.target.value,
                            };
                            setClientState(newClientState);
                        }}
                        />
                </>
            )}
                <CInputGroupText>Zip Code</CInputGroupText>
                <CFormInput
                    id="zip"
                    value={clientState.zip}
                    disabled={viewOnly}
                    onChange={(e) => {
                        const newClientState = {
                            ...clientState,
                            zip: e.target.value,
                        };
                        setClientState(newClientState);
                    }}
                />

                <CInputGroupText>Country</CInputGroupText>
                <CFormSelect
                    id="country"
                    value={clientState.country}
                    disabled={viewOnly}
                    options={countries.map(country => ({ label: country.name, value: country.code }))}
                    onChange={(e) => {
                        const newCountry = e.target.value;
                        const newClientState = {
                            ...clientState,
                            country: newCountry,
                            state: '', // Reset state/province when country changes
                        };
                        setClientState(newClientState);
                    }}
                />
            </CInputGroup>

            <CInputGroup className="mb-3  py-3">
                <CInputGroupText>Beneficiary</CInputGroupText>
                <CFormInput
                id="beneficiary"
                value={clientState.beneficiaries[0]} // Assuming you want to edit the first beneficiary
                disabled={viewOnly}
                onChange={(e) => {
                    const newBeneficiaries = [...clientState.beneficiaries];
                    newBeneficiaries[0] = e.target.value; // Update the first beneficiary
                    const newClientState = {
                    ...clientState,
                    beneficiaries: newBeneficiaries,
                    };
                    setClientState(newClientState);
                }}
                />
            </CInputGroup>

            <CInputGroup className="mb-3  py-3">
                <CInputGroupText>App Email</CInputGroupText>
                <CFormInput value={clientState.appEmail}  disabled={true}/>
                <CInputGroupText>UID</CInputGroupText>
                <CFormInput value={clientState.uid}  disabled={true}/>
            </CInputGroup>

            <CMultiSelect 
                id="connected-clients"
                className="mb-3  py-3" 
                options={clientOptions} 
                placeholder="Select Connected Clients" 
                selectAll={false}
                disabled={viewOnly}
                onChange={
                (selectedValues) => {
                    const updatedOptions = clientOptions.map(option => ({
                        ...option,
                        selected: selectedValues.some(selected => selected.value === option.value),
                    }));
                    const newClientState = {
                        ...clientState,
                        connectedUsers: selectedValues.map(selected => selected.value as string)
                    }
                    
                    setClientOptions(updatedOptions);
                    setClientState(newClientState)
                }
                }
            /> 
            
            <CInputGroup className='py-3'>
                <CInputGroupText>YTD</CInputGroupText>
                <CFormInput type="number" id="ytd" value={clientState.ytd} disabled={viewOnly}
                onChange={(e) => {
                    const newClientState = {
                    ...clientState,
                    ytd: parseFloat(e.target.value),
                    };
                    setClientState(newClientState)
                }}/>
                <CLoadingButton 
                color="primary" 
                variant="outline" 
                disabled={clientState.cid == '' || clientState.cid == null || viewOnly} 
                loading={ytdLoading}
                onClick={async () => {    
                    setYTDLoading(true);
                    try {const ytd = await db.getYTD(clientState.cid); 
                    const newClientState = {
                        ...clientState,
                        ytd: ytd,
                    };
                    setClientState(newClientState);
                    } catch (error) {
                    console.error(error);
                    } finally {
                    setYTDLoading(false);
                    }
                }}
                >Update YTD</CLoadingButton>
            </CInputGroup>
            <CInputGroup className='py-3'>
                <CInputGroupText>Total YTD</CInputGroupText>
                <CFormInput type="number" id="ytd" value={clientState.totalYTD ?? clientState.ytd} disabled={clientState.connectedUsers.length == 0 || viewOnly}
                onChange={(e) => {
                    const newClientState = {
                    ...clientState,
                    ytd: parseFloat(e.target.value),
                    };
                    setClientState(newClientState)
                }}/>
                <CLoadingButton 
                color="primary" 
                variant="outline" 
                disabled={clientState.connectedUsers.length == 0 || clientState.cid == '' || clientState.cid == null || viewOnly} 
                loading={totalYTDLoading}
                onClick={async () => {    
                    setTotalYTDLoading(true);
                    try {const ytd = await db.getTotalYTD(clientState.cid); 
                    const newClientState = {
                        ...clientState,
                        totalYTD: ytd,
                    };
                    setClientState(newClientState);
                    } catch (error) {
                    console.error(error);
                    } finally {
                    setTotalYTDLoading(false);
                    }
                }}
                >Update Total YTD</CLoadingButton>
            </CInputGroup>

            <EditAssetsSection clientState={clientState} setClientState={setClientState} viewOnly={viewOnly}/>

            <CInputGroup className='pb-5'>
                <CInputGroupText>Notes</CInputGroupText>
                <CFormTextarea
                    id="notes"
                    value={clientState.notes}
                    placeholder="Enter notes here..."
                    onChange={(e) => {
                        setClientState({ ...clientState, notes: e.target.value });
                    }}
                />
            </CInputGroup>

            <div className="my-3 ">
                <h5>Upload Previous Activities</h5>
                <div  className="mb-3 py-3">
                <CFormInput type="file" id="formFile" onChange={(event) => handleActivitiesFileChange(event, clientState, setClientState)} disabled={viewOnly}/>
                </div>
            </div>
            
            {/* Imported Activities Table */}
            {(clientState.activities && clientState.activities.length > 0) && <CTable striped hover >
                <CTableHead >
                <CTableRow>
                    <CTableHeaderCell>Index</CTableHeaderCell>
                    <CTableHeaderCell>Fund</CTableHeaderCell>
                    <CTableHeaderCell>Type</CTableHeaderCell>
                    <CTableHeaderCell>Recipient</CTableHeaderCell>
                    <CTableHeaderCell>Time</CTableHeaderCell>
                    <CTableHeaderCell>Amount</CTableHeaderCell>
                    <CTableHeaderCell>Actions</CTableHeaderCell>
                </CTableRow>
                </CTableHead>
                <CTableBody>
                {clientState.activities?.map((activity, index) => {
                const isEditing = editActivityIndex === index;
                return (
                    <CTableRow key={index}>
                    <CTableDataCell>{index + 1}</CTableDataCell>
                    {isEditing ? (
                        // Editable fields when in edit mode
                        <>
                        <CTableDataCell style={{ width: '120px'}} >
                            <CFormSelect 
                                value={editedActivity?.fund || ''}
                                onChange={(e) => setEditedActivity({ ...editedActivity, fund: e.target.value.toLowerCase() })
                                }
                                options={[
                                    { label: 'AK1', value: 'AK1' },
                                    { label: 'AGQ', value: 'AGQ' },
                                ]}
                            />
                        </CTableDataCell>
                        <CTableDataCell  style={{ width: '125px'}} >
                            <CFormSelect 
                                value={editedActivity?.type || ''}
                                onChange={(e) => setEditedActivity({ ...editedActivity, type: e.target.value.toLowerCase() })
                                }
                                options={[
                                    { label: 'Profit', value: 'profit' },
                                    { label: 'Deposit', value: 'deposit' },
                                    { label: 'Withdrawal', value: 'withdrawal'},
                                ]}
                            />
                        </CTableDataCell>
                        <CTableDataCell>
                            <CFormInput
                            value={editedActivity?.recipient || ''}
                            onChange={(e) =>
                                setEditedActivity({ ...editedActivity, recipient: e.target.value })
                            }
                            />
                        </CTableDataCell>
                        <CTableDataCell className="d-flex gap-2">
                            <CFormInput
                            type="date"
                            value={
                                editedActivity?.time
                                ? editedActivity.time.toISOString().split('T')[0]
                                : ''
                            }
                            onChange={(e) => {
                                const newTime = parseDateWithTwoDigitYear(e.target.value) || new Date();
                                setEditedActivity({
                                ...editedActivity,
                                time: newTime,
                                formattedTime: formatDate(newTime),
                                });
                            }}
                            />
                        </CTableDataCell>
                        <CTableDataCell >
                        <CFormInput
                            type="number"
                            value={editedActivity?.amount || ''}
                            onChange={(e) => {
                                const value = parseFloat(e.target.value);
                                setEditedActivity({
                                ...editedActivity!,
                                amount: !isNaN(value) ? value : 0, // Ensure amount is a number
                                });
                            }}
                        />
                        </CTableDataCell>
                        <CTableDataCell className="d-flex gap-2">
                            <CButton
                            className='me-2'
                            color="success"
                            variant="outline"
                            onClick={() => {
                                // Update the activity in the client state
                                const updatedActivities = [...(clientState.activities || [])];
                                updatedActivities[index] = editedActivity!;
                                setClientState({
                                ...clientState,
                                activities: updatedActivities,
                                });
                                setEditActivityIndex(null);
                                setEditedActivity(emptyActivity);
                            }}
                            >
                            Save
                            </CButton>
                            <CButton
                            color="secondary"
                            variant="outline"
                            onClick={() => {
                                // Cancel editing
                                setEditActivityIndex(null);
                                setEditedActivity(emptyActivity);
                            }}
                            >
                            Cancel
                            </CButton>
                        </CTableDataCell>
                        </>
                    ) : (
                        // Static fields when not in edit mode
                        <>
                        <CTableDataCell>{activity.fund}</CTableDataCell>
                        <CTableDataCell>{toTitleCase(activity.type)}</CTableDataCell>
                        <CTableDataCell>{activity.recipient}</CTableDataCell>
                        <CTableDataCell>{activity.formattedTime}</CTableDataCell>
                        <CTableDataCell>{formatCurrency(activity.amount)}</CTableDataCell>
                        <CTableDataCell className="d-flex gap-2">
                            <CButton
                                color="warning"
                                variant="outline"
                                className="me-3" // Adds margin-end
                                onClick={() => {
                                setEditActivityIndex(index);
                                setEditedActivity({ ...activity }); // Clone the activity
                                }}
                            >
                                Edit
                            </CButton>
                            <CButton
                                color="danger"
                                variant="outline"
                                onClick={() => handleRemoveActivity(index)}
                            >
                                Remove
                            </CButton>
                            </CTableDataCell>
                        </>
                    )}
                    </CTableRow>
                );
                })}
                </CTableBody>
            </CTable>}

{/* 
            <div className="mb-3 ">
                <h5>Upload Graph Points</h5>
                <div  className="mb-3 py-3">
                <CFormInput type="file" id="formFile" onChange={(event) => handleGraphPointsFileChange(event, clientState, setClientState)} disabled={viewOnly}/>
                </div>
            </div> */}
            </CModalBody>
    )
} 

export const ValidateClient = (clientState: Client, setInvalidInputFields: (fields: string[]) => void) => {
    let validClient = true;
    let fields: string[] = [];

    const fieldValidations: { displayName: string, condition: boolean }[] = [
        { displayName: 'First Name', condition: clientState.firstName === '' },
        { displayName: 'Last Name', condition: clientState.lastName === '' },
        { displayName: 'Street', condition: clientState.street === '' },
        { displayName: 'City', condition: clientState.city === '' },
        { displayName: 'Country', condition: clientState.country === '' },
        { displayName: 'State/Province', condition: clientState.country === 'US' ? clientState.state === '' : clientState.province === '' },
        { displayName: 'Zip Code', condition: clientState.zip === '' },
        { displayName: 'DOB', condition: !clientState.dob || isNaN(clientState.dob.getTime()) },
        { displayName: 'Phone Number', condition: clientState.phoneNumber === '' },
        { displayName: 'Email', condition: clientState.initEmail === '' },
        { displayName: 'First Deposit Date', condition: !clientState.firstDepositDate || isNaN(clientState.firstDepositDate.getTime()) },
        { displayName: 'Beneficiary', condition: clientState.beneficiaries[0] === '' },
    ];

    fieldValidations.forEach(({ displayName, condition }) => {
        if (condition) {
            fields.push(displayName);
            validClient = false;
        }
    });
    
    setInvalidInputFields(fields);

    return validClient;
}
