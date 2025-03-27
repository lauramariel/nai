1. Modify milvus-values.yaml
2. Install Milvus
   ```
   python3 install-milvus.sh
   ```
3. Identify MilvusDB IP
   ```
   kubectl get svc milvus-vectordb -n milvus -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```
4. Modify doc-ingest.py to specify Milvus DB IP obtained above
5. Create venv and install requirements
    ```
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

6. Run doc-ingest.py
    ```
    time python3 doc-ingest.py
    ```
