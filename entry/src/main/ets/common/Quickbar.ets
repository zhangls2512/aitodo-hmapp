import { quickBarManager } from '@kit.DeskTopExtensionKit'
import { getTodoInfo } from './Dataget'

interface QuickBarTodoItem {
  taskId: number,
  todoId: string
}

export async function getQuickBarTodoIdList(context: Context) {
  try {
    const customCategories = await quickBarManager.getCustomCategories(context)
    const todoCustomCategory = customCategories.find(item => item.categoryName === '常用待办')
    if (todoCustomCategory) {
      try {
        const todoTasks = await quickBarManager.getTasksFromCategory(context, todoCustomCategory.categoryId)
        return todoTasks.map(item => {
          const parameters = item.taskInfo.parameters
          if (parameters) {
            return String(parameters.find(item => item.key === 'todoId')?.value)
          }
          return ''
        }).filter(item => item)
      } catch {
        return []
      }
    } else {
      return []
    }
  } catch {
    return []
  }
}

export async function setQuickBarTodo(context: Context, todoId: string, todoName: string) {
  try {
    await quickBarManager.addCustomCategory(context, '常用待办')
  } catch {
  }
  const customCategories = await quickBarManager.getCustomCategories(context)
  const todoCustomCategory = customCategories.find(item => item.categoryName === '常用待办')
  if (todoCustomCategory) {
    try {
      const todoTaskArray = await quickBarManager.getTasksFromCategory(context, todoCustomCategory.categoryId)
      const todoTasks = todoTaskArray.map((item): QuickBarTodoItem => {
        const parameters = item.taskInfo.parameters
        if (parameters) {
          return {
            taskId: item.taskId,
            todoId: String(parameters.find(item => item.key === 'todoId')?.value)
          }
        }
        return {
          taskId: -1,
          todoId: ''
        }
      }).filter(item => item.todoId)
      const todoTask = todoTasks.find(item => item.todoId === todoId)
      if (!todoTask) {
        await quickBarManager.addQuickTask(context, todoCustomCategory.categoryId, {
          taskName: todoName,
          abilityName: 'EntryAbility',
          parameters: [
            {
              key: 'action',
              value: 'todoInfo'
            },
            {
              key: 'todoId',
              value: todoId
            }
          ]
        })
      }
      if (todoTask) {
        await quickBarManager.updateQuickTask(context, {
          taskId: todoTask.taskId,
          categoryId: todoCustomCategory.categoryId,
          taskInfo: {
            taskName: todoName,
            abilityName: 'EntryAbility',
            parameters: [
              {
                key: 'action',
                value: 'todoInfo'
              },
              {
                key: 'todoId',
                value: todoId
              }
            ]
          }
        })
      }
    } catch {
      await quickBarManager.addQuickTask(context, todoCustomCategory.categoryId, {
        taskName: todoName,
        abilityName: 'EntryAbility',
        parameters: [
          {
            key: 'action',
            value: 'todoInfo'
          },
          {
            key: 'todoId',
            value: todoId
          }
        ]
      })
    }
  }
}

export async function deleteQuickBarTodo(context: Context, todoId: string) {
  try {
    const customCategories = await quickBarManager.getCustomCategories(context)
    const todoCustomCategory = customCategories.find(item => item.categoryName === '常用待办')
    if (todoCustomCategory) {
      const todoTasks = await quickBarManager.getTasksFromCategory(context, todoCustomCategory.categoryId)
      const promises = todoTasks.map(async (item) => {
        const parameters = item.taskInfo.parameters
        if (parameters) {
          if (parameters.find(item => item.key === 'todoId')?.value === todoId) {
            await quickBarManager.deleteQuickTask(context, item.taskId)
          }
        }
      })
      await Promise.all(promises)
      const todoIds = await getQuickBarTodoIdList(context)
      if (todoIds.length === 0) {
        await quickBarManager.deleteCustomCategory(context, todoCustomCategory.categoryId)
      }
    }
  } catch {
  }
}

export async function syncQuickBarTodo(context: Context) {
  const todoIds = await getQuickBarTodoIdList(context)
  const promises = todoIds.map(async (item) => {
    const todo = await getTodoInfo(context, item)
    if (todo !== 'fail') {
      await setQuickBarTodo(context, item, todo.content)
    }
    if (todo === 'fail') {
      await deleteQuickBarTodo(context, item)
    }
  })
  await Promise.all(promises)
}