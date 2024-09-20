export default interface extern {
  terminateInstance: (instanceId: string) => Promise<void>,
}
