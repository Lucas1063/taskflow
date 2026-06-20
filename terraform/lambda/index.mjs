// terraform/lambda/index.mjs
import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';
const sns = new SNSClient({ region: 'us-east-1' });
const TOPIC = process.env.SNS_TOPIC_ARN;
export const handler = async (event) => {
  for (const record of event.Records) {
    const dados = JSON.parse(record.body);
    const msg = 'Tarefa ' + dados.tipo + ': ' + dados.titulo;
    await sns.send(new PublishCommand({ TopicArn: TOPIC, Message: msg,
      Subject: 'TaskFlow - aviso de tarefa' }));
  }
  return { ok: true };
};
