# large uploads

Users with large file uploads is a recurring support issue.  The
standard procedure should be to enable direct upload on their
datasets/collections, via pointing it to one of our S3 stores (all the
custom stores come with increased individual file sizes and enabled
direct upload). The curation team makes the decision whether a
specific user/collection etc. qualifies for extra storage allotments
(and which of the custom stores should be used - i.e., what file size
limit should be configured for them).

Once a custom store has been configured, the nature of direct upload
can be explained to the user using the template under directupload/
here. It is not uncommon for users with slow-ish network connections
to be struggling with large file uploads via the UI even with direct
upload enabled. In such a case the recommended procedure is to suggest
using the command line tool (DVUploader). See the template under
directuploader/. There is some unecdotal evidence of the "slow-ish
network" really being the case for everybody not immediately on the
Harvard internal fast subnets. So with remote users who need to upload
multi-gigabyte files, it may make sense to proceed to the command line
tool recommendation right away.