# Parent Image
FROM python3:12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 5002 to the outside world
EXPOSE 5002

# Run the application
CMD ["python", "app.py"]

