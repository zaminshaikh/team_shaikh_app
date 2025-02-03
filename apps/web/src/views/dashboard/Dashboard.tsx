
import { useTranslation } from 'react-i18next'
import ClientsTable from './ClientTable'

const Dashboard = () => {
  useTranslation()
  return (
      <ClientsTable />
  )
}

export default Dashboard
