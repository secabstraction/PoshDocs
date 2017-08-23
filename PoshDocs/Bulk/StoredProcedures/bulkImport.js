
function bulkImport(transactionId, docs) {
    var collection = getContext().getCollection();
    var collectionLink = collection.getSelfLink();

    var count = 0;

    if (!docs) throw new Error("The array is undefined or null.");
    if (!transactionId) throw new Error("The transactionId is undefined or null.")

    var docsLength = docs.length;
    if (docsLength == 0) {
        getContext().getResponse().setBody(0);
        return;
    }

    tryCreateDoc(docs[count], tryCreateNextDoc);

    function tryCreateDoc(doc, callback) {
        doc.transactionId = transactionId;
        var isAccepted = collection.createDocument(collectionLink, doc, tryCreateNextDoc);
        if (!isAccepted) getContext().getResponse().setBody(count);
    }

    function tryCreateNextDoc(err, doc, options) {
        if (err) throw err;

        count++;

        if (count >= docsLength) {
            getContext().getResponse().setBody(count);
        } else {
            tryCreateDoc(docs[count], tryCreateNextDoc);
        }
    }
}