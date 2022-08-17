
SELECT instance_id, account_id, region, title,
	instance_state, instance_type, vpc_id,
	private_ip_address, public_ip_address,
	key_name, iam_instance_profile_arn,
	metadata_options ->> 'HttpTokens' as IMDSv2,
	launch_time, state_transition_time, tags
FROM aws_all.aws_ec2_instance
-- WHERE status='ACTIVE'
