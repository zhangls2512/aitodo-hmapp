import { getPersonalAccountAccessToken } from './Account'
import { developerRequest } from './Request'

export default async function getCloudServiceStatus(context: Context) {
  const accessToken = await getPersonalAccountAccessToken()
  if (accessToken) {
    const accountInfoResponse = await developerRequest(context, '/account/getAccountInfo', {
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