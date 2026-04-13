const { app, BrowserWindow } = require('electron');
const path = require('node:path');
const { runRuntimeValidation } = require('./runtimeValidation.cjs');

const validationOutputPath = process.env.FOCUS_TODO_RUNTIME_VALIDATION_OUTPUT;
const validationPhase = process.env.FOCUS_TODO_RUNTIME_VALIDATION_PHASE;
const validationUserDataPath = process.env.FOCUS_TODO_RUNTIME_VALIDATION_USER_DATA;
const isRuntimeValidation = Boolean(validationOutputPath && validationPhase);

if (validationUserDataPath) {
  app.setPath('userData', path.resolve(validationUserDataPath));
}

function createMainWindow() {
  const mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 960,
    minHeight: 640,
    autoHideMenuBar: true,
    backgroundColor: '#f7f7f5',
    show: !isRuntimeValidation,
    webPreferences: {
      contextIsolation: true,
      devTools: !app.isPackaged,
      nodeIntegration: false,
    },
  });

  mainWindow.removeMenu();
  mainWindow.loadFile(path.join(__dirname, '..', 'dist', 'index.html'));
  return mainWindow;
}

app.whenReady().then(() => {
  const mainWindow = createMainWindow();

  if (isRuntimeValidation) {
    void runRuntimeValidation({
      app,
      mainWindow,
      outputPath: path.resolve(validationOutputPath),
      phase: validationPhase,
    });
  }

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
