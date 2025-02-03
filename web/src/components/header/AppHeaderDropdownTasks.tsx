import React from 'react'
import { useTranslation } from 'react-i18next'
import {
  CBadge,
  CDropdown,
  CDropdownDivider,
  CDropdownHeader,
  CDropdownItem,
  CDropdownMenu,
  CDropdownToggle,
  CProgress,
} from '@coreui/react-pro'
import CIcon from '@coreui/icons-react'
import { cilList } from '@coreui/icons'

const AppHeaderDropdownTasks = () => {
  const { t } = useTranslation()
  const itemsCount = 5
  return (
    <CDropdown variant="nav-item" alignment="end">
      <CDropdownToggle caret={false}>
        <CIcon icon={cilList} size="lg" className="my-1 mx-2" />
        <CBadge
          shape="rounded-pill"
          color="warning-gradient"
          className="position-absolute top-0 end-0"
        >
          {itemsCount}
        </CBadge>
      </CDropdownToggle>
      <CDropdownMenu className="pt-0">
        <CDropdownHeader className="bg-body-secondary text-body-secondary fw-semibold rounded-top mb-2">
          {t('taskCounter', { counter: itemsCount })}
        </CDropdownHeader>
        <CDropdownItem className="d-block py-2">
          <div className="d-flex justify-content-between mb-1">
            <div className="small">Upgrade NPM</div>
            <div className="fw-semibold">0%</div>
          </div>
          <CProgress thin color="info-gradient" value={0} />
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="d-flex justify-content-between mb-1">
            <div className="small">ReactJS Version</div>
            <div className="fw-semibold">25%</div>
          </div>
          <CProgress thin color="danger-gradient" value={25} />
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="d-flex justify-content-between mb-1">
            <div className="small">VueJS Version</div>
            <div className="fw-semibold">50%</div>
          </div>
          <CProgress thin color="warning-gradient" value={50} />
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="d-flex justify-content-between mb-1">
            <div className="small">Add new layouts</div>
            <div className="fw-semibold">75%</div>
          </div>
          <CProgress thin color="info-gradient" value={75} />
        </CDropdownItem>
        <CDropdownItem className="d-block py-2">
          <div className="d-flex justify-content-between mb-1">
            <div className="small">Angular Version</div>
            <div className="fw-semibold">100%</div>
          </div>
          <CProgress thin color="success-gradient" value={100} />
        </CDropdownItem>
        <CDropdownDivider />
        <CDropdownItem className="text-center fw-semibold" href="#">
          {t('viewAllTasks')}
        </CDropdownItem>
      </CDropdownMenu>
    </CDropdown>
  )
}

export default AppHeaderDropdownTasks
