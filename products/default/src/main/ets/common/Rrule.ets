import { calendarManager } from '@kit.CalendarKit'
import { getCustomFreqList } from './Customfreq'
import { icsTimeStringToTimeStamp } from './Ics'

interface RecentTodoStartEndTime {
  startTime: number,
  endTime: number
}

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
    if (key === 'INTERVAL') {
      result.interval = Number(value)
    }
    if (key === 'UNTIL') {
      result.expire = icsTimeStringToTimeStamp(value)
    }
    if (key === 'COUNT') {
      result.count = Number(value)
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

export function getRecentTodoFromFreq(context: Context, rRule: string, startTime: number, endTime: number,
  excludeTime: number[],
  currentTime: number) {
  let freq = ''
  let interval = 1
  let until = -1
  let maxCount = -1
  let byDay: number[] = []
  let byMonthday: number[] = []
  let byMonth: number[] = []
  const rfcFreq = ['YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY']
  const customFreq = getCustomFreqList(context)
  const tokens = rRule.split(';')
  const keyValues = tokens.map(item => item.split('='))
  keyValues.forEach(item => {
    const key = item[0]
    const value = item[1]
    if (key === 'FREQ') {
      const validFreqs = rfcFreq.concat(customFreq.map(item => item.name))
      if (validFreqs.includes(value)) {
        freq = value
      }
    }
    if (key === 'INTERVAL') {
      interval = Number(value)
    }
    if (key === 'UNTIL') {
      until = icsTimeStringToTimeStamp(value, true)
    }
    if (key === 'COUNT') {
      maxCount = Number(value)
    }
    if (key === 'BYDAY') {
      const dayMap: Record<string, number> = {
        'SU': 0,
        'MO': 1,
        'TU': 2,
        'WE': 3,
        'TH': 4,
        'FR': 5,
        'SA': 6
      }
      const days = value.split(',')
      const res: number[] = []
      days.forEach(item => {
        if (dayMap[item]) {
          res.push(dayMap[item])
        }
      })
      byDay = res
    }
    if (key === 'BYMONTHDAY') {
      byMonthday = value.split(',').map(item => Number(item))
    }
    if (key === 'BYMONTH') {
      byMonth = value.split(',').map(item => Number(item))
    }
  })
  if (!freq) {
    return {
      startTime: startTime,
      endTime: endTime
    } as RecentTodoStartEndTime
  }
  const date = new Date(startTime)
  let i = 0
  let count = 0
  const result: RecentTodoStartEndTime = {
    startTime: startTime,
    endTime: endTime
  }
  if (!rfcFreq.includes(freq)) {
    const ymdList = customFreq.find(item => item.name === freq)?.list
    let ymdIndex = 0
    while (ymdList && ymdIndex < ymdList.length &&
      isWhile(date, result.startTime, result.endTime, until, maxCount, currentTime, count) && i <= 40000) {
      i++
      if (isValid(date, byDay, byMonthday, byMonth, excludeTime)) {
        result.startTime = date.getTime()
        count++
      }
      date.setFullYear(ymdList[ymdIndex].year, ymdList[ymdIndex].month - 1, ymdList[ymdIndex].day)
      ymdIndex++
      if (date.getTime() >= currentTime) {
        if (endTime !== -1) {
          result.endTime = result.startTime + endTime - startTime
        }
        if (endTime === -1 && date.getTime() > currentTime && isValid(date, byDay, byMonthday, byMonth, excludeTime)) {
          result.endTime = date.getTime()
        }
      }
    }
  }
  if (rfcFreq.includes(freq)) {
    while (isWhile(date, result.startTime, result.endTime, until, maxCount, currentTime, count) && i <= 40000) {
      i++
      if (isValid(date, byDay, byMonthday, byMonth, excludeTime)) {
        result.startTime = date.getTime()
        count++
      }
      if (freq === 'YEARLY') {
        date.setFullYear(date.getFullYear() + 1 * interval, date.getMonth(), date.getDate())
      }
      if (freq === 'MONTHLY') {
        date.setMonth(date.getMonth() + 1 * interval, date.getDate())
      }
      if (freq === 'WEEKLY') {
        date.setDate(date.getDate() + 7 * interval)
      }
      if (freq === 'DAILY') {
        date.setDate(date.getDate() + 1 * interval)
      }
      if (date.getTime() >= currentTime) {
        if (endTime !== -1) {
          result.endTime = result.startTime + endTime - startTime
        }
        if (endTime === -1 && date.getTime() > currentTime && isValid(date, byDay, byMonthday, byMonth, excludeTime)) {
          result.endTime = date.getTime()
        }
      }
    }
  }
  if (!isValid(date, byDay, byMonthday, byMonth, excludeTime)) {
    result.startTime = -1
    result.endTime = -1
  }
  return result
}

function isWhile(date: Date, startTime: number, endTime: number, until: number, maxCount: number, currentTime: number,
  count: number) {
  if (startTime > currentTime) {
    return false
  }
  if (date.getTime() > until) {
    return false
  }
  if (count > maxCount) {
    return false
  }
  if (date.getTime() > currentTime && endTime !== -1) {
    return false
  }
  return true
}

function isValid(date: Date, byDay: number[], byMonthday: number[], byMonth: number[], excludeTime: number[]) {
  if (byDay.length > 0 && !byDay.includes(date.getDay())) {
    return false
  }
  if (byMonthday.length > 0 && !byMonthday.includes(date.getDate())) {
    return false
  }
  if (byMonth.length > 0 && !byMonth.includes(date.getMonth() + 1)) {
    return false
  }
  if (excludeTime.includes(date.getTime())) {
    return false
  }
  return true
}