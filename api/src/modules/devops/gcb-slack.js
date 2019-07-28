const axios = require('axios');

module.exports.gcbSlack = async e => {
  const build = JSON.parse(new Buffer(e.data, 'base64').toString());

  // Skip if the current status is not in the status list.
  // Add additional statues to list if you'd like:
  // QUEUED, WORKING, SUCCESS, FAILURE,
  // INTERNAL_ERROR, TIMEOUT, CANCELLED
  const status = ['SUCCESS', 'FAILURE', 'INTERNAL_ERROR', 'TIMEOUT'];
  if (status.indexOf(build.status) === -1) {
    return;
  }

  // Send message to Slack.
  axios.post(process.env.ALERTS_SLACK_WEBHOOK_URL, {
    data: {
      text: `Build \`${build.id}\``,
      mrkdwn: true,
      attachments: [
        {
          title: 'Build logs',
          title_link: build.logUrl,
          fields: [
            {
              title: 'Status',
              value: build.status
            }
          ]
        }
      ]
    }
  });
};
