import { test, expect } from '@playwright/test';

const baseURL = process.env.WEB_E2E_BASE_URL ?? 'http://127.0.0.1:8080';
const taskTitle = 'Playwright web task';

async function enableFlutterSemantics(page) {
  // Flutter Web keeps its accessibility DOM off until explicitly enabled.
  const toggle = page.locator('flt-semantics-placeholder');
  await toggle.waitFor({ state: 'attached' });
  await toggle.evaluate((node) => node.click());
  await expect(page.getByRole('button', { name: 'Добавить задачу' })).toBeVisible();
}

test('add, complete, persist, delete and persist deletion in Flutter Web', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto(baseURL);
  await expect(page).toHaveTitle('Мои задачи');
  await enableFlutterSemantics(page);

  const input = page.getByRole('textbox');
  const addButton = page.getByRole('button', { name: 'Добавить задачу' });
  const savedTask = page.locator('flt-semantics[aria-label*="' + taskTitle + '"]');

  await expect(page.locator('flt-semantics[aria-label*="Задач пока нет"]')).toBeVisible();

  await input.click();
  // Give Flutter's semantic text editor a frame to attach its input listener.
  await page.waitForTimeout(250);
  await input.fill(taskTitle);
  await addButton.click();

  // A task still sitting in the input must not count as a successful add.
  await expect(input).toBeEmpty();
  await expect(savedTask).toBeVisible();
  await expect(page.locator('flt-semantics[aria-label*="Задач пока нет"]')).toHaveCount(0);

  const completed = page.getByRole('checkbox');
  await expect(completed).toHaveCount(1);
  await completed.click();
  await expect(completed).toBeChecked();

  await page.reload();
  await enableFlutterSemantics(page);
  await expect(savedTask).toBeVisible();
  await expect(page.getByRole('checkbox')).toBeChecked();

  await page.getByRole('button', { name: 'Удалить задачу' }).click();
  await expect(savedTask).toHaveCount(0);
  await expect(page.locator('flt-semantics[aria-label*="Задач пока нет"]')).toBeVisible();

  await page.reload();
  await enableFlutterSemantics(page);
  await expect(savedTask).toHaveCount(0);
  await expect(page.locator('flt-semantics[aria-label*="Задач пока нет"]')).toBeVisible();
});
