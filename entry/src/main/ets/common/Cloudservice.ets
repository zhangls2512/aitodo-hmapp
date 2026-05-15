import { getPersonalAccountAccessToken } from './Account'
import request from './Request'

export default async function getCloudServiceStatus(context: Context) {
  const accessToken = await getPersonalAccountAccessToken()
  if (accessToken) {
    const accountInfoResponse = await request(context, '/account/getAccountInfo', {
      accessToken: accessToken
    })
    if (accountInfoResponse !== 'fail') {
      const services = JSON.parse(accountInfoResponse).data.service as string[]
      return services.includes('todo')
    }
    return false
  }
  return false
}