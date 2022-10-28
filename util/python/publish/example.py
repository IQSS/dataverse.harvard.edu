published_dois = []

for doi in dois:
    # let's try and publish it.
    url_request = "%s/datasets/:persistentId/actions/:publish?persistentId=%s&type=%s" % (api.base_url_api_native, doi, MAJOR_OR_MINOR)
    r = requests.post(url_request, headers=headers)
    # check the response:
    publish_status=r.status_code
    if publish_status != 200:
        print('failed to submit an api request to publish the dataset.')
        continue
    response_text=json.loads(r.text)
    sleep(10)
    # check the locks:
    while True:
        locks_api_url = "%s/datasets/:persistentId/locks?persistentId=%s" % (api.base_url_api_native, doi)
        resp_locks=api.get_request(locks_api_url, True)
        # print(resp_locks.json())
        dataset_locked=False
        if 'data' in resp_locks.json().keys():
            for lock_entry in resp_locks.json()['data']:
                lock_type=lock_entry['lockType']
                print(lock_type)
                if lock_type == 'finalizePublication':
                    dataset_locked = True
                    print('dataset locked. will sleep and try again.')
        else:
            print('failed to get a valid response from /locks api; will sleep and try again.')
            dataset_locked = True
        if dataset_locked:
            sleep(10)
        else:
            print('dataset unlocked. proceeding to the next one.')
            break
    published_dois.append(response_text)
