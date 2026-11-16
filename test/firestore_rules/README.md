Emulator tests for `firestore.rules` (needs Java + Node):

    cd test/firestore_rules
    npm i --no-save firebase-tools@13.29.1 @firebase/rules-unit-testing@4.0.1 firebase@11.1.0
    echo '{"emulators":{"firestore":{"port":8080},"ui":{"enabled":false}}}' > firebase.json
    RULES=../../firestore.rules npx firebase emulators:exec --only firestore --project hash-rules-test "node --test rules.test.mjs"
