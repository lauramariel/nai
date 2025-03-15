import lancedb

uri = "/Users/laura.jordana/Library/Application Support/anythingllm-desktop/storage/lancedb/nai.lance/data"
db = lancedb.connect(uri)
print(db.table_names())
