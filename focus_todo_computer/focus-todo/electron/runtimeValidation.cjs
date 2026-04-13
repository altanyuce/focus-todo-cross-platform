const fs = require('node:fs/promises');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function serializeFunction(fn, arg) {
  return `
    (async () => {
      try {
        return await (${fn.toString()})(${JSON.stringify(arg ?? null)});
      } catch (error) {
        return {
          __runtimeValidationError: true,
          message: error instanceof Error ? error.message : String(error),
          stack: error instanceof Error ? error.stack : null,
        };
      }
    })()
  `;
}

async function inRenderer(mainWindow, fn, arg) {
  const result = await mainWindow.webContents.executeJavaScript(
    serializeFunction(fn, arg),
    true,
  );

  if (result?.__runtimeValidationError) {
    throw new Error(result.stack || result.message || 'Renderer validation error');
  }

  return result;
}

async function waitFor(mainWindow, description, fn, arg, timeoutMs = 10000) {
  const startedAt = Date.now();

  while (Date.now() - startedAt < timeoutMs) {
    const result = await inRenderer(mainWindow, fn, arg);
    if (result) return result;
    await sleep(100);
  }

  throw new Error(`Timed out waiting for ${description}`);
}

async function waitForLoad(mainWindow) {
  await new Promise((resolve) => {
    if (!mainWindow.webContents.isLoadingMainFrame()) {
      resolve();
      return;
    }

    mainWindow.webContents.once('did-finish-load', resolve);
  });

  await waitFor(
    mainWindow,
    'application shell',
    () =>
      Boolean(
        document.querySelector('header') &&
          document.querySelector('input[type="search"]') &&
          document.querySelector('input[type="text"]') &&
          document.querySelectorAll('article, [role="group"]').length > 0,
      ),
  );
}

function pageLines(value) {
  return String(value ?? '')
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
}

async function getVisibleTaskTitles(mainWindow) {
  return inRenderer(mainWindow, () => {
    const lines = (element) =>
      String(element?.innerText ?? '')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean);

    return Array.from(document.querySelectorAll('article'))
      .map((article) => lines(article)[0] ?? null)
      .filter(Boolean);
  });
}

async function quickAddTask(mainWindow, title) {
  await inRenderer(mainWindow, (taskTitle) => {
    const input = document.querySelector('input[type="text"]');
    const form = input?.closest('form');
    if (!(input instanceof HTMLInputElement) || !(form instanceof HTMLFormElement)) {
      throw new Error('Quick add input not found');
    }

    input.focus();
    const valueSetter = Object.getOwnPropertyDescriptor(
      HTMLInputElement.prototype,
      'value',
    )?.set;

    valueSetter?.call(input, taskTitle);
    input.dispatchEvent(new Event('input', { bubbles: true }));
    form.requestSubmit();
  }, title);

  await waitFor(
    mainWindow,
    `task "${title}" to appear`,
    (taskTitle) => {
      const lines = (element) =>
        String(element?.innerText ?? '')
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean);

      return Array.from(document.querySelectorAll('article')).some(
        (article) => lines(article)[0] === taskTitle,
      );
    },
    title,
  );
}

async function clickSection(mainWindow, section) {
  await inRenderer(mainWindow, (sectionName) => {
    const indexBySection = {
      today: 0,
      upcoming: 1,
      completed: 2,
    };
    const button = Array.from(document.querySelectorAll('aside nav button'))[
      indexBySection[sectionName]
    ];

    if (!(button instanceof HTMLButtonElement)) {
      throw new Error(`Section button "${sectionName}" not found`);
    }

    button.click();
  }, section);

  await sleep(200);
}

async function setSelectValue(mainWindow, position, value) {
  await inRenderer(mainWindow, ({ position: nextPosition, value: nextValue }) => {
    const select = Array.from(document.querySelectorAll('select'))[nextPosition];

    if (!(select instanceof HTMLSelectElement)) {
      throw new Error(`Select at position ${nextPosition} not found`);
    }

    select.value = nextValue;
    select.dispatchEvent(new Event('change', { bubbles: true }));
  }, { position, value });

  await sleep(200);
}

async function clickTaskCheckbox(mainWindow, title) {
  await inRenderer(mainWindow, (taskTitle) => {
    const lines = (element) =>
      String(element?.innerText ?? '')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean);

    const article = Array.from(document.querySelectorAll('article')).find(
      (candidate) => lines(candidate)[0] === taskTitle,
    );
    const checkbox = article?.querySelector('input[type="checkbox"]');

    if (!(checkbox instanceof HTMLInputElement)) {
      throw new Error(`Checkbox for "${taskTitle}" not found`);
    }

    checkbox.click();
  }, title);

  await sleep(300);
}

async function clickTaskButton(mainWindow, title, buttonIndex) {
  await inRenderer(mainWindow, ({ taskTitle, nextButtonIndex }) => {
    const lines = (element) =>
      String(element?.innerText ?? '')
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean);

    const article = Array.from(document.querySelectorAll('article')).find(
      (candidate) => lines(candidate)[0] === taskTitle,
    );
    const buttons = Array.from(article?.querySelectorAll('button') ?? []);
    const button = buttons[nextButtonIndex];

    if (!(button instanceof HTMLButtonElement)) {
      throw new Error(`Button index ${nextButtonIndex} for "${taskTitle}" not found`);
    }

    button.click();
  }, { taskTitle: title, nextButtonIndex: buttonIndex });

  await sleep(200);
}

async function getSortValue(mainWindow) {
  return inRenderer(mainWindow, () => {
    const selects = Array.from(document.querySelectorAll('select'));
    const sortSelect = selects[selects.length - 1];
    return sortSelect instanceof HTMLSelectElement ? sortSelect.value : null;
  });
}

async function getSearchValue(mainWindow) {
  return inRenderer(mainWindow, () => {
    const input = document.querySelector('input[type="search"]');
    return input instanceof HTMLInputElement ? input.value : null;
  });
}

async function getTaskStorageSnapshot(mainWindow) {
  return inRenderer(mainWindow, () => {
    const raw = localStorage.getItem('focus-todo-task-data-v2');
    return raw ? JSON.parse(raw) : null;
  });
}

async function setLocalStorageValue(mainWindow, key, value) {
  await inRenderer(mainWindow, ({ key: nextKey, value: nextValue }) => {
    localStorage.setItem(nextKey, nextValue);
  }, { key, value });
}

async function removeLocalStorageValue(mainWindow, key) {
  await inRenderer(mainWindow, (nextKey) => {
    localStorage.removeItem(nextKey);
  }, key);
}

async function runUiFlowPhase(mainWindow) {
  await waitForLoad(mainWindow);

  const emptyStateBeforeAdd = await inRenderer(mainWindow, () =>
    Boolean(document.querySelector('[data-testid="empty-state"]')),
  );

  await quickAddTask(mainWindow, 'Zulu task');
  await quickAddTask(mainWindow, 'Alpha task');
  await quickAddTask(mainWindow, 'Charlie task');
  await quickAddTask(mainWindow, 'Bravo task');

  await setSelectValue(mainWindow, 4, 'title-asc');
  const titleAscOrder = await getVisibleTaskTitles(mainWindow);

  await setSelectValue(mainWindow, 4, 'title-desc');
  const titleDescOrder = await getVisibleTaskTitles(mainWindow);

  await clickTaskCheckbox(mainWindow, 'Bravo task');
  await waitFor(
    mainWindow,
    'Bravo task to leave Today after completion',
    (taskTitle) => {
      const lines = (element) =>
        String(element?.innerText ?? '')
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean);

      return !Array.from(document.querySelectorAll('article')).some(
        (article) => lines(article)[0] === taskTitle,
      );
    },
    'Bravo task',
  );

  await clickSection(mainWindow, 'completed');
  const completedTitles = await getVisibleTaskTitles(mainWindow);

  await clickSection(mainWindow, 'today');
  await clickTaskButton(mainWindow, 'Alpha task', 1);
  await clickTaskButton(mainWindow, 'Alpha task', 0);
  await waitFor(
    mainWindow,
    'Alpha task to disappear after delete',
    (taskTitle) => {
      const lines = (element) =>
        String(element?.innerText ?? '')
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean);

      return !Array.from(document.querySelectorAll('article')).some(
        (article) => lines(article)[0] === taskTitle,
      );
    },
    'Alpha task',
  );

  await sleep(700);

  const todayTitlesAfterDelete = await getVisibleTaskTitles(mainWindow);
  const taskStorageSnapshot = await getTaskStorageSnapshot(mainWindow);
  const alphaRecord =
    taskStorageSnapshot?.data?.tasks?.find?.((task) => task.title === 'Alpha task') ?? null;
  const bravoRecord =
    taskStorageSnapshot?.data?.tasks?.find?.((task) => task.title === 'Bravo task') ?? null;

  return {
    emptyStateBeforeAdd,
    titleAscOrder,
    titleDescOrder,
    completedTitles,
    todayTitlesAfterDelete,
    alphaSoftDeleted: Boolean(alphaRecord?.deletedAt),
    bravoCompleted: bravoRecord?.completed === true,
    persistedTaskCount: Array.isArray(taskStorageSnapshot?.data?.tasks)
      ? taskStorageSnapshot.data.tasks.length
      : null,
  };
}

async function runRestartPhase(mainWindow) {
  await waitForLoad(mainWindow);

  const todayTitles = await getVisibleTaskTitles(mainWindow);
  const sortValue = await getSortValue(mainWindow);

  await clickSection(mainWindow, 'completed');
  const completedTitles = await getVisibleTaskTitles(mainWindow);
  const taskStorageSnapshot = await getTaskStorageSnapshot(mainWindow);
  const alphaRecord =
    taskStorageSnapshot?.data?.tasks?.find?.((task) => task.title === 'Alpha task') ?? null;

  return {
    todayTitles,
    sortValue,
    completedTitles,
    alphaStillSoftDeleted: Boolean(alphaRecord?.deletedAt),
  };
}

async function runMalformedDataPhase(mainWindow) {
  await waitForLoad(mainWindow);

  await setLocalStorageValue(mainWindow, 'focus-todo-task-data-v2', '{');
  await setLocalStorageValue(mainWindow, 'focus-todo-ui-state-v1', '{');
  mainWindow.webContents.reload();
  await waitForLoad(mainWindow);

  const invalidJsonFallback = {
    emptyStateVisible: await inRenderer(mainWindow, () =>
      Boolean(document.querySelector('[data-testid="empty-state"]')),
    ),
    sortValue: await getSortValue(mainWindow),
    searchValue: await getSearchValue(mainWindow),
  };

  await removeLocalStorageValue(mainWindow, 'focus-todo-task-data-v2');
  await removeLocalStorageValue(mainWindow, 'focus-todo-ui-state-v1');
  await setLocalStorageValue(
    mainWindow,
    'focus-todo-state-v1',
    JSON.stringify({
      tasks: [
        {
          id: 'legacy-1',
          title: 'Legacy task',
          note: 123,
          dueDate: 'bad-date',
          priority: 'urgent',
          category: 'other',
          completed: 'false',
          createdAt: 'bad-created-at',
          updatedAt: 'bad-updated-at',
        },
      ],
      ui: {
        section: 'bad-section',
        search: 42,
        statusFilter: 'weird',
        priorityFilter: 'urgent',
        categoryFilter: 'other',
        sortOrder: 'bad-sort',
      },
    }),
  );

  mainWindow.webContents.reload();
  await waitForLoad(mainWindow);

  return {
    invalidJsonFallback,
    legacyTaskTitles: await getVisibleTaskTitles(mainWindow),
    restoredSortValue: await getSortValue(mainWindow),
    restoredSearchValue: await getSearchValue(mainWindow),
    currentBodyLines: pageLines(
      await inRenderer(mainWindow, () => document.body.innerText),
    ),
  };
}

async function runPhase(mainWindow, phase) {
  switch (phase) {
    case 'ui-flow':
      return runUiFlowPhase(mainWindow);
    case 'restart':
      return runRestartPhase(mainWindow);
    case 'malformed-data':
      return runMalformedDataPhase(mainWindow);
    default:
      throw new Error(`Unknown runtime validation phase: ${phase}`);
  }
}

async function runRuntimeValidation({ app, mainWindow, outputPath, phase }) {
  try {
    const result = await runPhase(mainWindow, phase);
    await fs.writeFile(
      outputPath,
      JSON.stringify(
        {
          ok: true,
          phase,
          result,
        },
        null,
        2,
      ),
      'utf8',
    );
    await app.quit();
  } catch (error) {
    await fs.writeFile(
      outputPath,
      JSON.stringify(
        {
          ok: false,
          phase,
          error: error instanceof Error ? error.message : String(error),
          stack: error instanceof Error ? error.stack : null,
        },
        null,
        2,
      ),
      'utf8',
    );
    app.exit(1);
  }
}

module.exports = {
  runRuntimeValidation,
};
