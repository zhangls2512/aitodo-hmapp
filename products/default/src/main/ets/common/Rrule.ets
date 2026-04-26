import { calendarManager } from '@kit.CalendarKit'
import { icsTimeStringToTimeStamp } from './Ics'

export function parseRRule(rRule: string) {
  const result: calendarManager.RecurrenceRule = {
    recurrenceFrequency: calendarManager.RecurrenceFrequency.YEARLY
  }
  const tokens = rRule.split(';')
  const keyValues = tokens.map(item => item.split('='))
  keyValues.forEach(item => {
    const key = item[0]
    const value = item[1]
    if (key === 'FREQ') {
      const freqMap: Record<string, calendarManager.RecurrenceFrequency> = {
        'YEARLY': calendarManager.RecurrenceFrequency.YEARLY,
        'MONTHLY': calendarManager.RecurrenceFrequency.MONTHLY,
        'WEEKLY': calendarManager.RecurrenceFrequency.WEEKLY,
        'DAILY': calendarManager.RecurrenceFrequency.DAILY
      }
      if (freqMap[value]) {
        result.recurrenceFrequency = freqMap[value]
      }
    }
    if (key === 'UNTIL') {
      result.expire = icsTimeStringToTimeStamp(value)
    }
    if (key === 'COUNT') {
      result.count = Number(value)
    }
    if (key === 'INTERVAL') {
      result.interval = Number(value)
    }
    if (key === 'BYDAY') {
      const dayMap: Record<string, number> = {
        'MO': 1,
        'TU': 2,
        'WE': 3,
        'TH': 4,
        'FR': 5,
        'SA': 6,
        'SU': 7
      }
      const days = value.split(',')
      const res: number[] = []
      days.forEach(item => {
        if (dayMap[item]) {
          res.push(dayMap[item])
        }
      })
      result.daysOfWeek = res
    }
    if (key === 'BYMONTHDAY') {
      result.daysOfMonth = value.split(',').map(item => Number(item))
    }
    if (key === 'BYMONTH') {
      result.monthsOfYear = value.split(',').map(item => Number(item))
    }
  })
  return result
}