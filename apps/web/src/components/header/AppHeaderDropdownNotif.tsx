import React from 'react'
import { useTranslation } from 'react-i18next'
import {
  CBadge,
  CDropdown,
  CDropdownHeader,
  CDropdownItem,
  CDropdownMenu,
  CDropdownToggle,
  CProgress,
} from '@coreui/react-pro'
import CIcon from '@coreui/icons-react'
import {
  cilBasket,
  cilBell,
  cilChartPie,
  cilSpeedometer,
  cilUserFollow,
  cilUserUnfollow,
} from '@coreui/icons'

const AppHeaderDropdownNotif = () => {
  const { t } = useTranslation()
  const itemsCount = 5
  return (
    <CDropdown variant="nav-item" alignment="end">
      <CDropdownToggle caret={false}>
        <CIcon icon={cilBell} size="lg" className="my-1 mx-2" />
        <CBadge
          shape="rounded-pill"
          color="danger-gradient"
          className="position-absolute top-0 end-0"
        >
          {itemsCount}
        </CBadge>
      </CDropdownToggle>
      <CDropdownMenu className="pt-0">
        <CDropdownHeader className="bg-body-secondary text-body-secondary fw-semibold rounded-top mb-2">
          {t('notificationsCounter', { counter: itemsCount })}
        </CDropdownHeader>
        <CDropdownItem>
          <CIcon icon={cilUserFollow} className="me-2 text-success" /> {t('newUserRegistered')}
        </CDropdownItem>
        <CDropdownItem>
          <CIcon icon={cilUserUnfollow} className="me-2 text-danger" /> {t('userDeleted')}
        </CDropdownItem>
        <CDropdownItem>
          <CIcon icon={cilChartPie} className="me-2 text-info" /> {t('salesReportIsReady')}
        </CDropdownItem>
        <CDropdownItem>
          <CIcon icon={cilBasket} className="me-2 text-primary" /> {t('newClient')}
        </CDropdownItem>
        <CDropdownItem>
          <CIcon icon={cilSpeedometer} className="me-2 text-warning" /> {t('serverOverloaded')}
        </CDropdownItem>
        <CDropdownHeader className="bg-body-secondary text-body-secondary fw-semibold my-2">
          {t('server')}
        </CDropdownHeader>
        <CDropdownItem className="d-block py-2">
          <div className="text-uppercase small fw-semibold mb-1">{t('cpuUsage')}</div>
          <CProgress thin color="info-gradient" value={25} />
          <div className="text-body-secondary small">
            {t('cpuUsageDescription', {
              number_of_processes: 348,
              number_of_cores: '1/4',
            })}
          </div>
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="text-uppercase small fw-semibold mb-1">{t('memoryUsage')}</div>
          <CProgress thin color="warning-gradient" value={70} />
          <div className="text-body-secondary small">11444GB/16384MB</div>
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="text-uppercase small fw-semibold mb-1">{t('ssdUsage')}</div>
          <CProgress thin color="danger-gradient" value={90} />
          <div className="text-body-secondary small">243GB/256GB</div>
        </CDropdownItem>
      </CDropdownMenu>
    </CDropdown>
  )
}

export default AppHeaderDropdownNotif
