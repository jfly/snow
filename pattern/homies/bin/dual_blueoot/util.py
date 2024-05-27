def group_by(arr, *, unique=True, key):
    grouped = {}
    for el in arr:
        k = key(el)

        if unique:
            assert k not in grouped, "The given key is not unique for the array"
            grouped[k] = el
        else:
            if k not in grouped:
                grouped[k] = []
            grouped[k].append(el)

    return grouped


def chunkify(arr, size):
    return list(zip(*[iter(arr)] * size))
