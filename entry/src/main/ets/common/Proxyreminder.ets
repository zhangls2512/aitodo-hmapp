import { reminderAgentManager } from '@kit.BackgroundTasksKit'

export interface ProxyReminder {
  id: number,
  todoId: string,
  title: string,
  content: string,
  time: number
}

function generateId(arr: number[]) {
  const set = new Set(arr)
  let current = 0
  while (set.has(current)) {
    current++
  }
  return current
}

export async function setProxyReminder(data: ProxyReminder) {
  try {
    if (data.time > Date.now()) {
      const date = new Date(data.time)
      const res = await getProxyReminderList()
      const index = res.findIndex(item => item.todoId === data.todoId)
      if (index !== -1) {
        const body: reminderAgentManager.ReminderRequestCalendar = {
          reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
          actionButton: [
            {
              title: '关闭',
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
            }
          ],
          wantAgent: {
            pkgName: 'com.zhangxm.aitodo',
            abilityName: 'EntryAbility',
            parameters: {
              todoId: data.todoId
            }
          },
          title: data.title,
          content: data.content,
          notificationId: res[index].id,
          groupId: data.todoId,
          dateTime: {
            year: date.getFullYear(),
            month: date.getUTCMonth() + 1,
            day: date.getDate(),
            hour: date.getHours(),
            minute: date.getMinutes(),
            second: date.getSeconds()
          }
        }
        await reminderAgentManager.updateReminder(res[index].id, body)
      }
      if (index === -1) {
        const body: reminderAgentManager.ReminderRequestCalendar = {
          reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
          actionButton: [
            {
              title: '关闭',
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
            }
          ],
          wantAgent: {
            pkgName: 'com.zhangxm.aitodo',
            abilityName: 'EntryAbility',
            parameters: {
              todoId: data.todoId
            }
          },
          title: data.title,
          content: data.content,
          notificationId: generateId(res.map(item => item.id)),
          groupId: data.todoId,
          dateTime: {
            year: date.getFullYear(),
            month: date.getUTCMonth() + 1,
            day: date.getDate(),
            hour: date.getHours(),
            minute: date.getMinutes(),
            second: date.getSeconds()
          }
        }
        await reminderAgentManager.publishReminder(body)
      }
    }
  } catch {
  }
}

export async function cancelProxyReminder(id: string) {
  const res = await getProxyReminderList()
  const index = res.findIndex(item => item.todoId === id)
  if (index !== -1) {
    await reminderAgentManager.cancelReminder(res[index].id)
  }
}

export async function getProxyReminderList() {
  const result: ProxyReminder[] = []
  const res = await reminderAgentManager.getAllValidReminders()
  res.forEach(item => {
    const remind = item.reminderReq as reminderAgentManager.ReminderRequestCalendar
    result.push({
      id: item.reminderId,
      todoId: String(item.reminderReq.groupId),
      title: String(item.reminderReq.title),
      content: String(item.reminderReq.content),
      time: new Date(remind.dateTime.year, remind.dateTime.month - 1, remind.dateTime.day, remind.dateTime.hour,
        remind.dateTime.minute, remind.dateTime.second).getTime()
    })
  })
  return result
}

export async function isProxyReminderOn(id: string) {
  const res = await getProxyReminderList()
  const index = res.findIndex(item => item.todoId === id)
  if (index !== -1) {
    return true
  }
  return false
}

export async function isProxyReminderEnabled() {
  const res = await getProxyReminderList()
  if (res.length < 30) {
    return true
  }
  return false
}