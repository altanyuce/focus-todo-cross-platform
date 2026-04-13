import { Sidebar } from './Sidebar'
import { TopBar } from './TopBar'
import { QuickAdd } from './QuickAdd'
import { FilterStrip } from './FilterStrip'
import { TaskList } from './TaskList'
import styles from './AppShell.module.css'

export function AppShell() {
  return (
    <div className={styles.root}>
      <Sidebar />
      <div className={styles.main}>
        <TopBar />
        <div className={styles.content}>
          <QuickAdd />
          <FilterStrip />
          <TaskList />
        </div>
      </div>
    </div>
  )
}
