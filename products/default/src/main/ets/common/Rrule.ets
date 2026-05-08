import { calendarManager } from '@kit.CalendarKit'
import { getCustomFreqList } from './Customfreq'
import { icsTimeStringToTimeStamp, timeStampToIcsTimeString } from './Ics'

interface RecentTodoStartEndTime {
  startTime: number,
  endTime: number
}

export function parseRRule(rRule: string) {
  const result: calendarManager.RecurrenceRule = {
    recurrenceFrequency: calendarManager.RecurrenceFrequency.YEARLY
  }
  const tokens = rRule.split(';')
  const keyValues = tokens.map(item => item.split('=', 2))
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

export function stringifyRRule(rRule: string) {
  const rRuleObject = JSON.parse(rRule) as calendarManager.RecurrenceRule
  let result = 'FREQ='
  result += ['YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY'][rRuleObject.recurrenceFrequency]
  if (rRuleObject.expire) {
    result += ';UNTIL='
    result += timeStampToIcsTimeString(rRuleObject.expire)
  }
  if (rRuleObject.count) {
    result += ';COUNT='
    result += rRuleObject.count
  }
  if (rRuleObject.interval) {
    result += ';INTERVAL='
    result += rRuleObject.interval
  }
  if (rRuleObject.monthsOfYear) {
    result += ';BYMONTH='
    result += Object.values(rRuleObject.monthsOfYear).join(',')
  }
  if (rRuleObject.daysOfMonth) {
    result += ';BYMONTHDAY='
    result += Object.values(rRuleObject.daysOfMonth).join(',')
  }
  if (rRuleObject.daysOfWeek) {
    result += ';BYDAY='
    const dayMap: Record<number, string> = {
      1: 'MO',
      2: 'TU',
      3: 'WE',
      4: 'TH',
      5: 'FR',
      6: 'SA',
      7: 'SU'
    }
    result += Object.values(rRuleObject.daysOfWeek).map(item => dayMap[item]).join(',')
  }
  return result
}

export function getRecentTodoFromFreq(context: Context, rRule: string, startTime: number, endTime: number,
  excludeTime: number[], currentTime: number) {
  let freq = ''
  let interval = 1
  let until = Infinity
  let maxCount = Infinity
  let byDay = [0, 1, 2, 3, 4, 5, 6]
  let byMonthday =
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
  let byMonth = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  const rfcFreq = ['YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY']
  const customFreq = getCustomFreqList(context)
  const tokens = rRule.split(';')
  const keyValues = tokens.map(item => item.split('=', 2))
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
      byMonth = value.split(',').map(item => Number(item) - 1)
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
  const byDaySet = new Set<number>(byDay)
  const byMonthdaySet = new Set<number>(byMonthday)
  const byMonthSet = new Set<number>(byMonth)
  const excludeTimeSet = new Set<number>(excludeTime)
  if (!rfcFreq.includes(freq)) {
    const ymdList = customFreq.find(item => item.name === freq)?.list
    let ymdIndex = 0
    while (ymdList && ymdIndex < ymdList.length &&
      isWhile(date, result.startTime, result.endTime, until, maxCount, currentTime, count) && i <= 40000) {
      i++
      if (isValid(date, byDaySet, byMonthdaySet, byMonthSet, excludeTimeSet)) {
        result.startTime = date.getTime()
        count++
      }
      date.setFullYear(ymdList[ymdIndex].year, ymdList[ymdIndex].month - 1, ymdList[ymdIndex].day)
      ymdIndex++
      const timeStamp = date.getTime()
      if (timeStamp >= currentTime) {
        if (endTime !== -1) {
          result.endTime = result.startTime + endTime - startTime
        }
        if (endTime === -1 && timeStamp > currentTime &&
          isValid(date, byDaySet, byMonthdaySet, byMonthSet, excludeTimeSet)) {
          result.endTime = timeStamp
        }
      }
    }
  }
  if (rfcFreq.includes(freq)) {
    while (isWhile(date, result.startTime, result.endTime, until, maxCount, currentTime, count) && i <= 40000) {
      i++
      if (isValid(date, byDaySet, byMonthdaySet, byMonthSet, excludeTimeSet)) {
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
      const timeStamp = date.getTime()
      if (timeStamp >= currentTime) {
        if (endTime !== -1) {
          result.endTime = result.startTime + endTime - startTime
        }
        if (endTime === -1 && timeStamp > currentTime &&
          isValid(date, byDaySet, byMonthdaySet, byMonthSet, excludeTimeSet)) {
          result.endTime = timeStamp
        }
      }
    }
  }
  if (!isValid(date, byDaySet, byMonthdaySet, byMonthSet, excludeTimeSet)) {
    result.startTime = -1
    result.endTime = -1
  }
  return result
}

function isWhile(date: Date, startTime: number, endTime: number, until: number, maxCount: number, currentTime: number,
  count: number) {
  const timeStamp = date.getTime()
  if (startTime > currentTime) {
    return false
  }
  if (timeStamp > until) {
    return false
  }
  if (count >= maxCount) {
    return false
  }
  if (timeStamp > currentTime && endTime !== -1) {
    return false
  }
  return true
}

function isValid(date: Date, byDay: Set<number>, byMonthday: Set<number>, byMonth: Set<number>,
  excludeTime: Set<number>) {
  if (!byDay.has(date.getDay())) {
    return false
  }
  if (!byMonthday.has(date.getDate())) {
    return false
  }
  if (!byMonth.has(date.getMonth())) {
    return false
  }
  if (excludeTime.has(date.getTime())) {
    return false
  }
  return true
}