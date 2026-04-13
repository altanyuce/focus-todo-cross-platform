import { AppShell } from './components/AppShell'
import { TodoProvider } from './state/TodoProvider'

function App() {
  return (
    <TodoProvider>
      <AppShell />
    </TodoProvider>
  )
}

export default App
