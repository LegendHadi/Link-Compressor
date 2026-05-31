# Link Compressor Explanation

## Which components do you think this system needs?

- A user interface component for entering the original URL, optional keywords, and expiration settings.
- A component for generating a short link and displaying the result, including a QR code.
- A history component for listing generated links, searching existing entries, copying links, and deleting entries.
- A local storage component to persist link history across app restarts.
- A link generation component that builds a unique short link from the original URL and keywords.
- A backend/API component to store short links and resolve them when visited.

## What information should be stored?

- The original URL.
- The generated short URL.
- The creation time of the short link.
- Optional expiration details, such as a chosen expiry label and expiration timestamp.
- Any custom keywords used to influence the short URL.
- Metadata for managing history, such as a unique identifier or order.

## When a user opens a short link, what steps should the system perform?

- Receive the short link request.
- Look up the short link in the storage system or backend service.
- If the short link exists and is not expired, redirect the user to the original URL.
- If the short link is expired, show an expiration message or a suitable error page.
- If the short link does not exist, return a not found message.

## If two people register the same link, do you think the output should be the same or different? Why?

- It can depend on the design goals. For a deterministic local generator, the same input may produce the same output if the keywords and URL are identical.
- However, if the system is meant to provide unique short codes for each request, then the output should be different to avoid collisions and preserve separate records.
- In a real public link shortener, unique outputs are usually preferred so that each created link can be managed independently, even if the same original URL is shortened multiple times.

## What kinds of errors might occur, and how should the system handle them?

- Invalid URL input: validate that the input uses `http://` or `https://` and show a friendly error message.
- Duplicate short link collisions: detect collisions and generate a unique alternative or append a suffix.
- Storage failures: show a message if saving or loading link history fails, and retry if possible.
- Expired link access: inform the user the short link has expired instead of redirecting.
- Non-existent short link: display a clear not found response.

## If the number of links grows significantly, what problems might arise?

- Performance issues when searching and filtering the link history, especially if all links are loaded into memory.
- Increased storage use, which can become a problem with local device storage limits.
- Longer load and save times for link history if using a simple local storage solution.
- Greater risk of collisions if short link generation is not robust enough for many entries.
- The need for more advanced indexing, pagination, and backend storage mechanisms to handle large scale data.
