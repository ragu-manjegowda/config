package.path = os.getenv('HOME') .. '/.config/awesome/?.lua;' .. package.path

local email_subject = require('library.email-subject')

local first, second = email_subject.split('Short subject', 42)
assert(first == 'Short subject' and second == '', 'short subject was split')

first, second = email_subject.split(
    'Prepare service rollout for scheduled workflows and preserve the complete validation context',
    42
)
assert(first == 'Prepare service rollout for scheduled', 'first line did not split at a word boundary')
assert(second:match('%.%.%.$') ~= nil, 'second line was not capped with an ellipsis')

local unicode_subject = string.rep('a', 41) .. 'é workflow validation requires more context than one line'
first, second = email_subject.split(unicode_subject, 42)
assert(first:match('é$') ~= nil, 'UTF-8 character was split or removed from the first line')
assert(second:match('workflow') ~= nil, 'UTF-8 subject lost its second line')
assert(first:gsub('[%z\1-\127\194-\244][\128-\191]*', '') == '', 'first line is not valid UTF-8')
assert(second:gsub('[%z\1-\127\194-\244][\128-\191]*', '') == '', 'second line is not valid UTF-8')

print('email subject tests passed')
