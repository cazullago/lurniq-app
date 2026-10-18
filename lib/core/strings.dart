/// All user-facing strings in one place so the UI is translation-ready.
/// Phase 1 ships English; adding a language means adding a parallel catalog
/// and a lookup — no string is hard-coded in widgets outside this file.
library;

class S {
  // ── Brand ──────────────────────────────────────────────
  static const appName = 'Lurniq';
  static const tagline = 'A smarter way to learn.';
  static const demoMode =
      'Demo mode — accounts and data live on this device only.';
  static const demoBadge = 'DEMO';

  // ── Navigation ─────────────────────────────────────────
  static const navTutor = 'Tutor';
  static const navNewsfeed = 'Newsfeed';
  static const navAddPost = 'Add Post';
  static const navPlanner = 'Planner';
  static const navProfile = 'Profile';

  // ── Auth ───────────────────────────────────────────────
  static const welcomeTitle = 'Learn with the world.';
  static const welcomeSubtitle =
      'Ask questions, find tutors, organize your studies — wherever you are.';
  static const signIn = 'Sign in';
  static const createAccount = 'Create account';
  static const exploreDemo = 'Explore with a demo account';
  static const displayName = 'Display name';
  static const username = 'Username';
  static const emailOptional = 'Email (optional)';
  static const usernameTaken =
      'That username is taken. Try another one.';
  static const usernameUnknown =
      'No account with that username on this device.';
  static const nameRequired = 'Please enter a display name.';
  static const usernameRequired =
      'Usernames need at least 3 letters or numbers.';
  static const signedInAs = 'Signed in as';
  static const signOut = 'Sign out';
  static const signOutConfirm =
      'Sign out of your account on this device? Your data stays saved here.';
  static const deleteAccount = 'Delete account';
  static const deleteAccountTitle = 'Delete your account?';
  static const deleteAccountBody =
      'This permanently removes your profile and everything you created on this device. This cannot be undone.';
  static const delete = 'Delete';
  static const keepAccount = 'Keep my account';

  // ── Common ─────────────────────────────────────────────
  static const cancel = 'Cancel';
  static const save = 'Save';
  static const done = 'Done';
  static const close = 'Close';
  static const retry = 'Retry';
  static const confirm = 'Confirm';
  static const search = 'Search';
  static const searchHint = 'Search…';
  static const filters = 'Filters';
  static const sortBy = 'Sort by';
  static const newest = 'Newest';
  static const mostHelpful = 'Most helpful';
  static const clearFilters = 'Clear filters';
  static const apply = 'Apply';
  static const all = 'All';
  static const free = 'Free';
  static const paid = 'Paid';
  static const optional = 'optional';
  static const required = 'required';
  static const loading = 'Loading…';
  static const copied = 'Copied to clipboard.';
  static const somethingWrong =
      'Something went wrong. Please try again.';
  static const offlineNote =
      'You appear to be offline. Your work is saved on this device.';

  // ── Tutor tab ──────────────────────────────────────────
  static const tutorTitle = 'Find a tutor';
  static const tutorSearchHint = 'Search tutors, subjects…';
  static const tutorSubject = 'Subject';
  static const tutorLevel = 'Education level';
  static const tutorCountry = 'Country';
  static const tutorLanguage = 'Language';
  static const tutorPricing = 'Pricing';
  static const tutorMinRating = 'Minimum rating';
  static const tutorMaxPrice = 'Max price / hour';
  static const tutorSortRating = 'Highest rated';
  static const tutorSortPriceLow = 'Price: low to high';
  static const tutorSortPriceHigh = 'Price: high to low';
  static const tutorSortName = 'Name A–Z';
  static const noTutors = 'No tutors match your filters.';
  static const noTutorsHint = 'Try widening the price range or clearing filters.';
  static const perHour = '/hour';
  static const reviewsCount = 'reviews';
  static const viewProfile = 'View profile';
  static const tutorOnline = 'Online now';
  static const tutorAvailability = 'Availability';
  static const tutorExperience = 'Experience';
  static const tutorQualifications = 'Qualifications';
  static const tutorTeaches = 'Teaches';
  static const tutorLanguages = 'Languages';
  static const tutorLocation = 'Based in';
  static const tutorReviews = 'Reviews';
  static const noReviewsYet = 'No reviews yet.';
  static const writeReview = 'Write a review';
  static const yourRating = 'Your rating';
  static const yourReview = 'Your review';
  static const reviewThanks = 'Thanks! Your review was posted.';
  static const verificationTitle = 'Verification';
  static const verificationUnverified = 'Unverified';
  static const verificationUnverifiedDetail =
      'This tutor has not completed identity verification. Their profile information is self-reported.';
  static const verificationId = 'ID verified';
  static const verificationIdDetail =
      'This tutor verified their identity with the platform. Subject expertise is still self-reported unless stated otherwise.';
  static const verificationCredential = 'Credential checked';
  static const verificationCredentialDetail =
      'This tutor provided a teaching credential that the platform reviewed. Always read reviews before booking.';
  static const becomeTutorTitle = 'Share what you know';
  static const becomeTutorBody =
      'Tutor registration opens in Phase 3. Anyone with real knowledge to share — students, self-taught learners, professionals, hobbyists — will be able to apply with low entry requirements and honest verification labels.';
  static const becomeTutorCta = 'Become a tutor';
  static const tutorInterestTitle = 'Get notified';
  static const tutorInterestBody =
      'Leave your name and how to reach you, plus what you could teach. We will notify you when tutor applications open.';
  static const contactInfo = 'How can we reach you?';
  static const whatTeach = 'What could you teach?';
  static const notifyMe = 'Notify me';
  static const interestSaved =
      'Saved! We will let you know when applications open.';
  static const coursesPhase3 = 'Recorded courses arrive in Phase 3.';
  static const bookingsPhase3 = 'Live tutoring bookings arrive in Phase 3.';
  static const commissionNote =
      'Tutors set their own prices. When payments launch, the platform will take a configurable commission (starting at 15%) — always shown before you pay.';
  static const demoTutorsNote =
      'These are sample tutor profiles for demonstration. Real tutor listings arrive with Phase 3.';

  // ── Newsfeed ───────────────────────────────────────────
  static const feedTitle = 'Newsfeed';
  static const feedSearchHint = 'Search posts…';
  static const feedEmpty = 'Nothing here yet.';
  static const feedEmptyHint =
      'Be the first to ask a question or share study notes with students around the world.';
  static const createFirstPost = 'Create a post';
  static const like = 'Like';
  static const comment = 'Comment';
  static const comments = 'Comments';
  static const reply = 'Reply';
  static const replies = 'Replies';
  static const bookmark = 'Save';
  static const bookmarked = 'Saved';
  static const follow = 'Follow';
  static const following = 'Following';
  static const unfollow = 'Unfollow';
  static const share = 'Share';
  static const report = 'Report';
  static const reportTitle = 'Report this post';
  static const reportReason = 'Why are you reporting this?';
  static const reportThanks =
      'Thanks — our moderators will take a look.';
  static const markHelpful = 'Mark as helpful answer';
  static const helpfulAnswer = 'Helpful answer';
  static const markResolved = 'Mark as resolved';
  static const resolved = 'Resolved';
  static const reopen = 'Reopen';
  static const addCommentHint = 'Write a comment…';
  static const writeReplyHint = 'Write a reply…';
  static const postComment = 'Post';
  static const deletePost = 'Delete post';
  static const deletePostConfirm =
      'Delete this post and all its comments? This cannot be undone.';
  static const deleteCommentConfirm = 'Delete this comment?';
  static const integrityTipTitle = 'Learn it, don’t just copy it';
  static const integrityTipBody =
      'Ask for explanations and show your working. Answers that you copy into graded work without understanding may breach your school’s academic integrity rules.';
  static const integrityComposerTip =
      'Tip: ask for an explanation, not just the answer — you will learn more, and stay within your school’s academic integrity rules.';
  static const announcementLabel = 'Announcement';

  // ── Add Post ───────────────────────────────────────────
  static const addPostTitle = 'Create';
  static const addPostSubtitle = 'What would you like to share?';
  static const optionGeneralPost = 'General post';
  static const optionGeneralPostDesc =
      'Ask a question, start a discussion, or share notes with the community.';
  static const optionStudyGroup = 'Study group invitation';
  static const optionStudyGroupDesc =
      'Invite students to study together, online or in person.';
  static const optionResource = 'Share a resource';
  static const optionResourceDesc =
      'Share your notes, guides, flashcards, or helpful links.';
  static const postTitle = 'Title';
  static const postTitleOptional = 'Title (optional)';
  static const postBody = 'What do you want to say?';
  static const postBodyHint =
      'Explain your question or share what you learned…';
  static const subject = 'Subject';
  static const educationLevel = 'Education level';
  static const tags = 'Tags';
  static const tagsHint = 'exam, algebra, tips (comma separated)';
  static const addImages = 'Add images';
  static const preview = 'Preview';
  static const publish = 'Publish';
  static const publishPost = 'Publish post';
  static const postPublished = 'Your post is live!';
  static const bodyRequired = 'Please write something first.';
  static const postType = 'Post type';

  // Study group
  static const groupTitle = 'Study group title';
  static const groupSubject = 'Subject / topic';
  static const groupDescription = 'Description and learning goals';
  static const groupDescriptionHint =
      'What will you study? What should participants prepare?';
  static const groupDate = 'Date';
  static const groupTime = 'Time';
  static const groupTimezoneNote =
      'Shown in each participant’s own timezone.';
  static const groupDuration = 'Duration (minutes)';
  static const groupMax = 'Max participants';
  static const groupFormat = 'Format';
  static const groupOnline = 'Online';
  static const groupInPerson = 'In person';
  static const groupLink = 'Meeting link';
  static const groupLocation = 'Location details';
  static const groupLocationSafety =
      'For everyone’s safety — especially minors — never share a precise home address. Use a public place or an online meeting.';
  static const publishInvitation = 'Publish invitation';
  static const invitationPublished = 'Invitation published!';
  static const joinGroup = 'Request to join';
  static const joinGroupPending = 'Request pending';
  static const leaveGroup = 'Leave group';
  static const joinedGroup = 'You’re in! See you there.';
  static const leftGroup = 'You left the study group.';
  static const groupFull = 'This group is full — you’ll join the waitlist.';
  static const participants = 'Participants';
  static const approve = 'Approve';
  static const cancelGroup = 'Cancel session';
  static const cancelGroupConfirm =
      'Cancel this study session? Participants will see that it was cancelled.';
  static const groupCancelled = 'This session was cancelled by the organizer.';
  static const yourGroups = 'Your study sessions';
  static const noGroupsYet = 'No study sessions yet.';
  static const spotsLeft = 'spots left';

  // Resource
  static const resourceTitle = 'Resource title';
  static const resourceDescription = 'Description';
  static const resourceDescriptionHint =
      'What is this resource and who is it for?';
  static const resourceKind = 'Resource type';
  static const resourceKinds = 'Notes, Study guide, Practice questions, Flashcards, Link, Other';
  static const resourceLink = 'Link (optional)';
  static const resourceAccess = 'Access';
  static const resourceFree = 'Free to access';
  static const resourceRestricted = 'Restricted (describe below)';
  static const resourceRestriction = 'Access details';
  static const shareResource = 'Share resource';
  static const resourceShared = 'Resource shared!';
  static const openLink = 'Open link';

  // ── Planner ────────────────────────────────────────────
  static const plannerTitle = 'Planner';
  static const tabFolders = 'Subjects';
  static const tabTasks = 'Tasks';
  static const tabCalendar = 'Calendar';
  static const newFolder = 'New subject';
  static const folderName = 'Subject name';
  static const folderNameHint = 'e.g. Biology';
  static const folderColor = 'Color';
  static const folderIcon = 'Icon';
  static const renameFolder = 'Rename';
  static const deleteFolder = 'Delete subject';
  static const deleteFolderConfirm =
      'Delete this subject and all its lessons and tasks? This cannot be undone.';
  static const noFolders = 'No subjects yet.';
  static const noFoldersHint =
      'Create a subject folder to start organizing your lessons and tasks.';
  static const lessons = 'Lessons';
  static const noLessons = 'No lessons saved here yet.';
  static const noLessonsHint =
      'Capture a photo of your textbook, notes, or whiteboard to save it here.';
  static const captureLesson = 'Capture lesson';
  static const choosePhotoSource = 'Add a lesson photo';
  static const takePhoto = 'Take photo';
  static const chooseFromGallery = 'Choose from gallery';
  static const cameraPermissionTitle = 'Camera access';
  static const cameraPermissionBody =
      'Lurniq uses your camera so you can photograph lessons, notes, and assignments. Photos stay on your device.';
  static const photosPermissionTitle = 'Photo library access';
  static const photosPermissionBody =
      'Lurniq needs access to your photos so you can attach lesson images. Photos stay on your device.';
  static const permissionDenied =
      'Permission denied. You can enable it anytime in your device settings.';
  static const openSettings = 'Open settings';
  static const lessonTitle = 'Lesson title';
  static const lessonTitleHint = 'e.g. Photosynthesis — Chapter 4';
  static const lessonNotes = 'Your notes';
  static const lessonNotesHint = 'Key points in your own words…';
  static const lessonDate = 'Lesson date';
  static const topicTags = 'Topics';
  static const topicTagsHint = 'fractions, homework ch.3';
  static const saveLesson = 'Save lesson';
  static const lessonSaved = 'Lesson saved.';
  static const viewPhoto = 'View photo';
  static const editLesson = 'Edit lesson';
  static const deleteLesson = 'Delete lesson';
  static const deleteLessonConfirm = 'Delete this lesson and its photo?';
  static const ocrPhase2 =
      'Text extraction (OCR) arrives in Phase 2 — for now, your photo and notes are saved together.';
  static const searchLessons = 'Search your lessons…';
  static const noLessonResults = 'No saved lessons match your search.';
  static const lessonCount = 'lessons';

  // Tasks
  static const newTask = 'New task';
  static const taskTitle = 'Task title';
  static const taskTitleHint = 'e.g. Chapter 5 exercises';
  static const taskInstructions = 'Instructions';
  static const taskInstructionsHint = 'What exactly needs to be done?';
  static const dueDate = 'Due date';
  static const dueTime = 'Due time';
  static const noDueDate = 'No due date';
  static const priority = 'Priority';
  static const priorityLow = 'Low';
  static const priorityMedium = 'Medium';
  static const priorityHigh = 'High';
  static const status = 'Status';
  static const statusTodo = 'To do';
  static const statusDoing = 'Doing';
  static const statusDone = 'Done';
  static const reminder = 'Reminder';
  static const reminderPhase2Note =
      'Push notifications arrive in Phase 2 — your reminder time is saved for now.';
  static const taskNotes = 'Notes';
  static const saveTask = 'Save task';
  static const taskSaved = 'Task saved.';
  static const deleteTask = 'Delete task';
  static const deleteTaskConfirm = 'Delete this task?';
  static const markDone = 'Mark done';
  static const noTasks = 'No tasks here.';
  static const noTasksHint = 'Add homework, projects, quizzes, or exams to stay on track.';
  static const overdue = 'Overdue';
  static const dueToday = 'Due today';
  static const dueTomorrow = 'Due tomorrow';
  static const upcoming = 'Upcoming';
  static const completed = 'Completed';
  static const allTasks = 'All';
  static const taskFromPhoto = 'From photo';
  static const taskFromPhotoPhase2 =
      'Reading assignments from photos arrives in Phase 2. You can attach the photo to your task for now.';
  static const attachPhoto = 'Attach photo';
  static const today = 'Today';
  static const thisWeek = 'This week';

  // ── Profile ────────────────────────────────────────────
  static const profileTitle = 'Profile';
  static const editProfile = 'Edit profile';
  static const profileSaved = 'Profile saved.';
  static const bio = 'Bio';
  static const bioHint = 'Tell other students about yourself…';
  static const country = 'Country / region';
  static const countryHint = 'e.g. Canada';
  static const preferredLanguage = 'Preferred language';
  static const school = 'School / institution';
  static const schoolOptional = 'School (optional)';
  static const interests = 'Subjects of interest';
  static const interestsHint = 'Physics, essay writing… (comma separated)';
  static const learningGoals = 'Learning goals';
  static const learningGoalsHint = 'Pass calculus, learn Spanish… (comma separated)';
  static const profilePhoto = 'Profile photo';
  static const privacy = 'Privacy';
  static const privacyPublic = 'Public';
  static const privacyFollowers = 'Followers';
  static const privacyPrivate = 'Private';
  static const privacyHint =
      'Control who sees each part of your profile. Your username is always visible.';
  static const tabPosts = 'Posts';
  static const tabSaved = 'Saved';
  static const tabFollowing = 'Following';
  static const tabCourses = 'Courses';
  static const noPostsYet = 'No posts yet.';
  static const noSavedYet = 'Nothing saved yet.';
  static const noSavedHint = 'Tap the bookmark icon on any post to find it here.';
  static const noFollowingYet = 'You’re not following anyone yet.';
  static const coursesPhase3Note =
      'Courses you enroll in will appear here. Recorded courses arrive in Phase 3.';
  static const memberSince = 'Member since';
  static const postsCount = 'Posts';
  static const followersCount = 'Followers';
  static const followingCount = 'Following';
  static const blockedUsers = 'Blocked users';
  static const noBlockedUsers = 'No blocked users.';
  static const unblock = 'Unblock';
  static const blockUser = 'Block user';
  static const blockUserConfirm =
      'Block this user? You won’t see their posts or comments anymore.';
  static const userBlocked = 'User blocked.';

  // Settings
  static const settings = 'Settings';
  static const account = 'Account';
  static const language = 'Language';
  static const languageNote = 'English for now — more languages arrive in Phase 5.';
  static const currencyDisplay = 'Currency display';
  static const currencyNote =
      'Prices are shown in USD until live conversion launches with payments (Phase 4).';
  static const timezone = 'Timezone';
  static const timezoneDevice = 'Device timezone (automatic)';
  static const notifications = 'Notifications';
  static const notifPush = 'Push notifications';
  static const notifLikes = 'Likes on my posts';
  static const notifComments = 'Replies and comments';
  static const notifReminders = 'Task reminders';
  static const notifGroups = 'Study group updates';
  static const notifPhase2Note =
      'Notification delivery is wired up in Phase 2 — your preferences are saved now.';
  static const helpSupport = 'Help & support';
  static const helpBody =
      'Phase 1 demo build.\n\nFor help, contact the Lurniq team through the project repository. A full help center ships before the public launch.';
  static const termsOfService = 'Terms of service';
  static const privacyPolicy = 'Privacy policy';
  static const legalPlaceholder =
      'The full legal text ships before the public launch. The template is tracked in the project repository (docs/privacy-policy-template.md).';
  static const resetDemoContent = 'Reset demo content';
  static const resetDemoContentConfirm =
      'Remove all demo tutors, posts, and comments? Your account and personal data stay untouched.';
  static const demoContentCleared = 'Demo content cleared.';
  static const dangerZone = 'Danger zone';

  // ── Admin ──────────────────────────────────────────────
  static const adminLoginTitle = 'Administrator';
  static const adminPasscode = 'Admin passcode';
  static const adminPasscodeHint = 'Enter the admin passcode';
  static const adminWrongCode = 'Incorrect passcode.';
  static const adminDashboard = 'Admin dashboard';
  static const adminUsers = 'Users';
  static const adminTutorApps = 'Tutor applications';
  static const adminCourses = 'Courses';
  static const adminContent = 'Content moderation';
  static const adminReports = 'Safety reports';
  static const adminTransactions = 'Transactions';
  static const adminCommission = 'Commission settings';
  static const adminRefunds = 'Refunds & disputes';
  static const adminAnnouncements = 'Announcements';
  static const adminLanguages = 'Languages & currencies';
  static const adminModeration = 'Moderation actions';
  static const adminAnalytics = 'Analytics';
  static const adminAuditLog = 'Audit log';
  static const noAuditEntries = 'No admin actions recorded yet.';
  static const commissionRate = 'Platform commission';
  static const commissionHint =
      'Applies to paid tutoring and course sales when payments launch (Phase 4).';
  static const commissionSaved = 'Commission updated.';
  static const openReports = 'Open reports';
  static const noOpenReports = 'No open reports. Nice.';
  static const dismissReport = 'Dismiss';
  static const hideContent = 'Hide content';
  static const reportResolvedAs = 'Report resolved';
  static const newAnnouncement = 'New announcement';
  static const announcementTitle = 'Announcement title';
  static const announcementBody = 'Message';
  static const announcementPublished = 'Announcement published.';
  static const noAnnouncements = 'No announcements yet.';
  static const deactivate = 'Deactivate';
  static const activate = 'Activate';
  static const phase5Note =
      'Full tooling for this area ships in Phase 5. Local demo data is shown where available.';
  static const adminSecurityNote =
      'On this demo build the dashboard is behind a passcode. Production deployments must enforce administrator roles server-side — a hidden gesture alone is not protection.';

  // ── Boot error screen ──────────────────────────────────
  static const bootErrorTitle = 'Lurniq couldn’t start';
  static const bootErrorBody =
      'Something went wrong while starting the app. Your data is safe. You can copy the technical details below and send them to the Lurniq team.';
  static const copyDetails = 'Copy details';

  // ── Misc ───────────────────────────────────────────────
  static const ok = 'OK';
  static const yes = 'Yes';
  static const by = 'by';
  static const editedSuffix = '(edited)';
  static const justNow = 'just now';
  static const minutesAgo = 'm ago';
  static const hoursAgo = 'h ago';
  static const daysAgo = 'd ago';

  // ── v2: Theme ──────────────────────────────────────────
  static const appearance = 'Appearance';
  static const themeMode = 'Day / night mode';
  static const themeSystem = 'Follow system';
  static const themeLight = 'Day';
  static const themeDark = 'Night';
  static const notSet = 'Not set';

  // ── v2: Planner tasks ──────────────────────────────────
  static const taskType = 'Task type';
  static const taskTypeHint = 'What kind of task is this?';
  static const doneFolder = 'Done';
  static const doneFolderSubtitle =
      'Finished tasks live here as your performance record.';
  static const reopenTask = 'Move back to to-do';
  static const logGrade = 'Log grade';
  static const gradeScoreHint = 'Score (e.g. 95/100 or A)';
  static const gradeNoteHint = 'Note (optional)';
  static const gradePhotoHint = 'Photo of your result (optional)';
  static const askAi = 'Ask AI';
  static const aiDemoBadge = 'Demo AI';
  static const aiDemoNote =
      'Demo AI gives guided, template-based help. Add your own API key in Settings for full AI answers.';
  static const aiApiKey = 'AI API key';
  static const aiApiKeyHint =
      'Paste an OpenAI-compatible API key. It stays on this device and is never shared.';
  static const aiApiKeySaved = 'API key saved on this device.';
  static const aiPlaceholder = 'Ask about this task or lesson…';
  static const aiThinking = 'Thinking…';

  // ── v2: Messaging ──────────────────────────────────────
  static const messages = 'Messages';
  static const messagesDemoNote =
      'Demo messaging — conversations live on this device only for now.';
  static const newMessage = 'New message';
  static const typeMessage = 'Type a message…';
  static const messageButton = 'Message';
  static const unblockUser = 'Unblock';
  static const reportUser = 'Report';
  static const noConversations = 'No conversations yet';
  static const noConversationsBody =
      'Tap Message on someone\u2019s profile to start chatting.';

  // ── v2: Tutor — courses ────────────────────────────────
  static const findTutors = 'Find Tutors';
  static const courses = 'Courses';
  static const countryFilter = 'Country';
  static const everyone = 'Everyone';
  static const myCountryOnly = 'My country only';
  static const createCourse = 'Create course';
  static const editCourse = 'Edit course';
  static const courseTitle = 'Course title';
  static const courseDescription = 'Description';
  static const addLesson = 'Add lesson';
  static const lessonKind = 'Lesson format';
  static const lessonVideo = 'Video';
  static const lessonSlides = 'Slides / text';
  static const videoUrlHint = 'Video link (https://…)';
  static const lessonBodyHint = 'Lesson content…';
  static const enroll = 'Enroll';
  static const enrolled = 'Enrolled';
  static const continueCourse = 'Continue';
  static const unpublish = 'Unpublish';
  static const published = 'Published';
  static const draft = 'Draft';
  static const myCourses = 'My courses';
  static const noCourses = 'No courses yet';
  static const noCoursesBody =
      'Tutors can publish pre-made video or slide lessons here.';
  static const courseEnrolledMsg = 'You\u2019re enrolled! Happy learning.';
  static const lessonDone = 'Mark lesson done';

  // ── v2: Tutor — 1v1 bookings ──────────────────────────
  static const bookSession = 'Book 1v1 session';
  static const myBookings = 'My sessions';
  static const bookingDateTime = 'Session date & time';
  static const bookingDuration = 'Duration';
  static const minutes = 'min';
  static const meetingLink = 'Meeting link';
  static const meetingLinkHint = 'Zoom / Google Meet link (https://…)';
  static const bookingNoteHint = 'What do you want to work on? (optional)';
  static const sendRequest = 'Send request';
  static const bookingSent = 'Request sent! The tutor can accept or decline.';
  static const accept = 'Accept';
  static const decline = 'Decline';
  static const bookingAccepted = 'Booking accepted. Reminder set!';
  static const bookingDeclined = 'Booking declined.';
  static const pendingRequests = 'Pending requests';
  static const upcomingSessions = 'Upcoming sessions';
  static const pastSessions = 'Past sessions';
  static const leaveReview = 'Leave a review';
  static const reviewHint = 'How was the session?';
  static const joinMeeting = 'Join meeting';
  static const bookingReminderTitle = 'Tutoring session soon';
  static const bookingReminderBody = 'Your 1v1 session starts in 15 minutes.';
  static const courseEnrollTitle = 'New course enrollment';
  static const bookingRequestTitle = 'New 1v1 booking request';

  // ── v2: Tutor — live sessions & quizzes ────────────────
  static const live = 'Live';
  static const scheduleLive = 'Schedule live session';
  static const liveTitle = 'Session title';
  static const goLive = 'Go live';
  static const endSession = 'End session';
  static const liveNow = 'LIVE NOW';
  static const noLive = 'No live sessions right now';
  static const noLiveBody =
      'Tutors can schedule public live sessions with interactive quizzes.';
  static const liveChat = 'Live chat';
  static const liveQuiz = 'Live quiz';
  static const createQuiz = 'Create quiz';
  static const addQuestion = 'Add question';
  static const questionHint = 'Question';
  static const optionHint = 'Option';
  static const correctAnswer = 'Correct answer';
  static const timerSeconds = 'Seconds per question';
  static const startQuiz = 'Start quiz';
  static const yourAnswer = 'Your answer';
  static const correct = 'Correct!';
  static const incorrect = 'Not quite';
  static const timeUp = 'Time\u2019s up!';
  static const quizScore = 'Your score';
  static const scoreboard = 'Scoreboard';
  static const answersHiddenNote =
      'Answers stay hidden until the timer ends.';
  static const openMeetingLink = 'Open meeting link';

  // ── v2: Lurniq Plus subscription ───────────────────────
  static const subscription = 'Subscription';
  static const plusTitle = 'Lurniq Plus';
  static const plusTagline =
      'Supercharge your studying with unlimited AI help.';
  static const freeTier = 'Free';
  static const plusMonthly = 'Plus Monthly';
  static const plusYearly = 'Plus Yearly';
  static const bestValue = 'Best value';
  static const currentPlan = 'Current plan';
  static const subscribe = 'Subscribe';
  static const comingSoon = 'Coming soon';
  static const comingSoonNote =
      'Subscriptions aren\u2019t open yet — Google Play Billing is coming. Tapping subscribe charges nothing today.';
  static const unlimitedAi = 'Unlimited AI study help';
  static const noKeyNeeded = 'No API key needed';
  static const earlyAccess = 'Early access to new features';
  static const supporterBadge = 'Supporter badge on your profile';
  static const everythingInFree = 'Everything in the free app';
  static const dailyAiQuotaNote = 'free demo AI questions per day';
  static const quotaExhaustedTitle = 'Daily free AI limit reached';
  static const quotaExhaustedBody =
      'You\u2019ve used today\u2019s free AI questions. Add your own API key in Settings for unlimited answers, or get Lurniq Plus.';
  static const viewPlus = 'See Lurniq Plus';
  static const perMonth = 'month';
  static const perYear = 'year';
  static const approxRateNote =
      'USD equivalents are approximate (about ₱58 = $1).';
}
