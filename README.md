Label EBS Volumes using association info and meta tags from instances (if available).
==============

Use Ruby & Fog to update the tagSet on EBS volumes in your zones to reflect the attachment info in their Name tags.

1. Make sure you have fog gem installed (`gem install fog`)
2. Edit auth.yml to include your AWS Access Key ID (`:aws_access_key_id`) and Secret Access Key (`:aws_secret_access_key`)
3. Edit regions array in auth.yml to suit your AWS regions.

Run `label_ebs_volumes.rb` to update the Name tags and optionally set `NameTagUpdatedAt` tag on all volumes. Volumes that already have a Name tag will be ignore while volumes that have no attachment info will be marked as "Unassociated".
